//===----------------------------------------------------------------------===//
//
// This source file is part of the Swift.org open source project
//
// Copyright (c) 2014 - 2023 Apple Inc. and the Swift project authors
// Licensed under Apache License v2.0 with Runtime Library Exception
//
// See https://swift.org/LICENSE.txt for license information
// See https://swift.org/CONTRIBUTORS.txt for the list of Swift project authors
//
//===----------------------------------------------------------------------===//

#include "RefactoringActions.h"
#include "swift/AST/DiagnosticsRefactoring.h"
#include "swift/AST/ParameterList.h"
#include "swift/AST/USRGeneration.h"
#include "swift/Basic/StringExtras.h"
#include "swift/Index/Index.h"

using namespace swift::refactoring;
using namespace swift::index;

static const ValueDecl *getRelatedSystemDecl(const ValueDecl *VD) {
  if (VD->getModuleContext()->isNonUserModule())
    return VD;
  for (auto *Req : VD->getSatisfiedProtocolRequirements()) {
    if (Req->getModuleContext()->isNonUserModule())
      return Req;
  }
  for (auto Over = VD->getOverriddenDecl(); Over;
       Over = Over->getOverriddenDecl()) {
    if (Over->getModuleContext()->isNonUserModule())
      return Over;
  }
  return nullptr;
}

/// Stores information about the reference that rename availability is being
/// queried on.
struct RenameRefInfo {
  SourceFile *SF;  ///< The source file containing the reference.
  SourceLoc Loc;   ///< The reference's source location.
  bool IsArgLabel; ///< Whether Loc is on an arg label, rather than base name.
};

static llvm::Optional<RefactorAvailabilityInfo>
renameAvailabilityInfo(const ValueDecl *VD,
                       llvm::Optional<RenameRefInfo> RefInfo) {
  RefactorAvailableKind AvailKind = RefactorAvailableKind::Available;
  if (getRelatedSystemDecl(VD)) {
    AvailKind = RefactorAvailableKind::Unavailable_system_symbol;
  } else if (VD->getClangDecl()) {
    AvailKind = RefactorAvailableKind::Unavailable_decl_from_clang;
  } else if (!VD->hasName()) {
    AvailKind = RefactorAvailableKind::Unavailable_has_no_name;
  }

  auto isInMacroExpansionBuffer = [](const ValueDecl *VD) -> bool {
    auto *module = VD->getModuleContext();
    auto *file = module->getSourceFileContainingLocation(VD->getLoc());
    if (!file)
      return false;

    return file->getFulfilledMacroRole() != llvm::None;
  };

  if (AvailKind == RefactorAvailableKind::Available) {
    SourceLoc Loc = VD->getLoc();
    if (!Loc.isValid()) {
      AvailKind = RefactorAvailableKind::Unavailable_has_no_location;
    } else if (isInMacroExpansionBuffer(VD)) {
      AvailKind = RefactorAvailableKind::Unavailable_decl_in_macro;
    }
  }

  if (isa<AbstractFunctionDecl>(VD)) {
    // Disallow renaming accessors.
    if (isa<AccessorDecl>(VD))
      return llvm::None;

    // Disallow renaming deinit.
    if (isa<DestructorDecl>(VD))
      return llvm::None;

    // Disallow renaming init with no arguments.
    if (auto CD = dyn_cast<ConstructorDecl>(VD)) {
      if (!CD->getParameters()->size())
        return llvm::None;

      if (RefInfo && !RefInfo->IsArgLabel) {
        NameMatcher Matcher(*(RefInfo->SF));
        auto Resolved = Matcher.resolve({RefInfo->Loc});
        if (Resolved.LabelRanges.empty())
          return llvm::None;
      }
    }

    // Disallow renaming 'callAsFunction' method with no arguments.
    if (auto FD = dyn_cast<FuncDecl>(VD)) {
      // FIXME: syntactic rename can only decide by checking the spelling, not
      // whether it's an instance method, so we do the same here for now.
      if (FD->getBaseIdentifier() == FD->getASTContext().Id_callAsFunction) {
        if (!FD->getParameters()->size())
          return llvm::None;

        if (RefInfo && !RefInfo->IsArgLabel) {
          NameMatcher Matcher(*(RefInfo->SF));
          auto Resolved = Matcher.resolve({RefInfo->Loc});
          if (Resolved.LabelRanges.empty())
            return llvm::None;
        }
      }
    }
  }

  // Always return local rename for parameters.
  // FIXME: if the cursor is on the argument, we should return global rename.
  if (isa<ParamDecl>(VD))
    return RefactorAvailabilityInfo{RefactoringKind::LocalRename, AvailKind};

  // If the indexer considers VD a global symbol, then we apply global rename.
  if (index::isLocalSymbol(VD))
    return RefactorAvailabilityInfo{RefactoringKind::LocalRename, AvailKind};
  return RefactorAvailabilityInfo{RefactoringKind::GlobalRename, AvailKind};
}

/// Given a cursor, return the decl and its rename availability. \c None if
/// the cursor did not resolve to a decl or it resolved to a decl that we do
/// not allow renaming on.
llvm::Optional<RenameInfo>
swift::ide::getRenameInfo(ResolvedCursorInfoPtr cursorInfo) {
  auto valueCursor = dyn_cast<ResolvedValueRefCursorInfo>(cursorInfo);
  if (!valueCursor)
    return llvm::None;

  ValueDecl *VD = valueCursor->typeOrValue();
  if (!VD)
    return llvm::None;

  if (auto *V = dyn_cast<VarDecl>(VD)) {
    // Always use the canonical var decl for comparison. This is so we
    // pick up all occurrences of x in case statements like the below:
    //   case .first(let x), .second(let x)
    //     fallthrough
    //   case .third(let x)
    //     print(x)
    VD = V->getCanonicalVarDecl();

    // If we have a property wrapper backing property or projected value, use
    // the wrapped property instead (i.e. if this is _foo or $foo, pretend
    // it's foo).
    if (auto *Wrapped = V->getOriginalWrappedProperty()) {
      VD = Wrapped;
    }
  }

  llvm::Optional<RenameRefInfo> refInfo;
  if (!valueCursor->getShorthandShadowedDecls().empty()) {
    // Find the outermost decl for a shorthand if let/closure capture
    VD = valueCursor->getShorthandShadowedDecls().back();
  } else if (valueCursor->isRef()) {
    refInfo = {valueCursor->getSourceFile(), valueCursor->getLoc(),
               valueCursor->isKeywordArgument()};
  }

  llvm::Optional<RefactorAvailabilityInfo> info =
      renameAvailabilityInfo(VD, refInfo);
  if (!info)
    return llvm::None;

  return RenameInfo{VD, *info};
}

class RenameRangeCollector : public IndexDataConsumer {
  StringRef usr;
  std::unique_ptr<StringScratchSpace> stringStorage;
  std::vector<RenameLoc> locations;

public:
  RenameRangeCollector(StringRef usr)
      : usr(usr), stringStorage(new StringScratchSpace()) {}

  RenameRangeCollector(const ValueDecl *D)
      : stringStorage(new StringScratchSpace()) {
    SmallString<64> SS;
    llvm::raw_svector_ostream OS(SS);
    printValueDeclUSR(D, OS);
    usr = stringStorage->copyString(SS.str());
  }

  RenameRangeCollector(RenameRangeCollector &&collector) = default;

  /// Take the resuls from the collector.
  /// This invalidates the collector and must only be called once.
  RenameLocs takeResults() {
    return RenameLocs(locations, std::move(stringStorage));
  }

private:
  bool indexLocals() override { return true; }
  void failed(StringRef error) override {}
  bool startDependency(StringRef name, StringRef path, bool isClangModule,
                       bool isSystem) override {
    return true;
  }
  bool finishDependency(bool isClangModule) override { return true; }

  Action startSourceEntity(const IndexSymbol &symbol) override {
    if (symbol.USR == usr) {
      if (auto loc = indexSymbolToRenameLoc(symbol)) {
        // Inside capture lists like `{ [test] in }`, 'test' refers to both the
        // newly declared, captured variable and the referenced variable it is
        // initialized from. Make sure to only rename it once.
        auto existingLoc = llvm::find_if(locations, [&](RenameLoc searchLoc) {
          return searchLoc.Line == loc->Line && searchLoc.Column == loc->Column;
        });
        if (existingLoc == locations.end()) {
          locations.push_back(std::move(*loc));
        } else {
          assert(existingLoc->OldName == loc->OldName &&
                 existingLoc->IsFunctionLike == loc->IsFunctionLike &&
                 "Asked to do a different rename for the same location?");
        }
      }
    }
    return IndexDataConsumer::Continue;
  }

  bool finishSourceEntity(SymbolInfo symInfo, SymbolRoleSet roles) override {
    return true;
  }

  llvm::Optional<RenameLoc>
  indexSymbolToRenameLoc(const index::IndexSymbol &symbol);
};

llvm::Optional<RenameLoc>
RenameRangeCollector::indexSymbolToRenameLoc(const index::IndexSymbol &symbol) {
  if (symbol.roles & (unsigned)index::SymbolRole::Implicit) {
    return llvm::None;
  }

  NameUsage usage = NameUsage::Unknown;
  if (symbol.roles & (unsigned)index::SymbolRole::Call) {
    usage = NameUsage::Call;
  } else if (symbol.roles & (unsigned)index::SymbolRole::Definition) {
    usage = NameUsage::Definition;
  } else if (symbol.roles & (unsigned)index::SymbolRole::Reference) {
    usage = NameUsage::Reference;
  } else {
    llvm_unreachable("unexpected role");
  }

  bool isFunctionLike = false;

  switch (symbol.symInfo.Kind) {
  case index::SymbolKind::EnumConstant:
  case index::SymbolKind::Function:
  case index::SymbolKind::Constructor:
  case index::SymbolKind::ConversionFunction:
  case index::SymbolKind::InstanceMethod:
  case index::SymbolKind::ClassMethod:
  case index::SymbolKind::StaticMethod:
    isFunctionLike = true;
    break;
  case index::SymbolKind::Class:
  case index::SymbolKind::Enum:
  case index::SymbolKind::Struct:
  default:
    break;
  }
  StringRef oldName = stringStorage->copyString(symbol.name);
  return RenameLoc{symbol.line, symbol.column, usage, oldName, isFunctionLike};
}

/// Get the decl context that we need to walk when renaming \p VD.
///
/// This \c DeclContext contains all possible references to \c VD within the
/// file.
DeclContext *getRenameScope(ValueDecl *VD) {
  auto *Scope = VD->getDeclContext();
  // There may be sibling decls that the renamed symbol is visible from.
  switch (Scope->getContextKind()) {
  case DeclContextKind::GenericTypeDecl:
  case DeclContextKind::ExtensionDecl:
  case DeclContextKind::TopLevelCodeDecl:
  case DeclContextKind::SubscriptDecl:
  case DeclContextKind::EnumElementDecl:
  case DeclContextKind::AbstractFunctionDecl:
    Scope = Scope->getParent();
    break;
  case DeclContextKind::AbstractClosureExpr:
  case DeclContextKind::Initializer:
  case DeclContextKind::SerializedLocal:
  case DeclContextKind::Package:
  case DeclContextKind::Module:
  case DeclContextKind::FileUnit:
  case DeclContextKind::MacroDecl:
    break;
  }

  return Scope;
}

/// Get the `RenameInfo` at `startLoc` and validate that we can perform local
/// rename on it (e.g. checking that the original definition isn't a system
/// symbol).
///
/// If the validation succeeds, return the `RenameInfo`, otherwise add an error
/// to `diags` and return `None`.
static llvm::Optional<RenameInfo>
getRenameInfoForLocalRename(SourceFile *sourceFile, SourceLoc startLoc,
                            DiagnosticEngine &diags) {
  auto cursorInfo = evaluateOrDefault(
      sourceFile->getASTContext().evaluator,
      CursorInfoRequest{CursorInfoOwner(sourceFile, startLoc)},
      new ResolvedCursorInfo());

  llvm::Optional<RenameInfo> info = getRenameInfo(cursorInfo);
  if (!info) {
    diags.diagnose(startLoc, diag::unresolved_location);
    return llvm::None;
  }

  switch (info->Availability.AvailableKind) {
  case RefactorAvailableKind::Available:
    break;
  case RefactorAvailableKind::Unavailable_system_symbol:
    diags.diagnose(startLoc, diag::decl_is_system_symbol, info->VD->getName());
    return llvm::None;
  case RefactorAvailableKind::Unavailable_has_no_location:
    diags.diagnose(startLoc, diag::value_decl_no_loc, info->VD->getName());
    return llvm::None;
  case RefactorAvailableKind::Unavailable_has_no_name:
    diags.diagnose(startLoc, diag::decl_has_no_name);
    return llvm::None;
  case RefactorAvailableKind::Unavailable_has_no_accessibility:
    diags.diagnose(startLoc, diag::decl_no_accessibility);
    return llvm::None;
  case RefactorAvailableKind::Unavailable_decl_from_clang:
    diags.diagnose(startLoc, diag::decl_from_clang);
    return llvm::None;
  case RefactorAvailableKind::Unavailable_decl_in_macro:
    diags.diagnose(startLoc, diag::decl_in_macro);
    return llvm::None;
  }

  return info;
}

RenameLocs swift::ide::localRenameLocs(SourceFile *SF, RenameInfo renameInfo) {
  DeclContext *RenameScope = SF;
  if (!RenameScope) {
    // If the value is declared in a DeclContext that's a child of the file in
    // which we are performing the rename, we can limit our analysis to this
    // decl context.
    //
    // Cases where the rename scope is not a child of the source file include
    // if we are getting related identifiers of a type A that is defined in
    // another file. In this case, we need to analyze the entire file.
    auto DeclarationScope = getRenameScope(renameInfo.VD);
    if (DeclarationScope->isChildContextOf(SF)) {
      RenameScope = DeclarationScope;
    }
  }

  RenameRangeCollector rangeCollector(renameInfo.VD);
  indexDeclContext(RenameScope, rangeCollector);

  return rangeCollector.takeResults();
}

int swift::ide::findLocalRenameRanges(SourceFile *SF, RangeConfig Range,
                                      FindRenameRangesConsumer &RenameConsumer,
                                      DiagnosticConsumer &DiagConsumer) {
  assert(SF && "null source file");

  SourceManager &SM = SF->getASTContext().SourceMgr;
  DiagnosticEngine Diags(SM);
  Diags.addConsumer(DiagConsumer);

  auto StartLoc = Lexer::getLocForStartOfToken(SM, Range.getStart(SM));
  llvm::Optional<RenameInfo> info =
      getRenameInfoForLocalRename(SF, StartLoc, Diags);
  if (!info) {
    // getRenameInfoForLocalRename has already produced an error in `Diags`.
    return true;
  }

  RenameLocs RenameRanges = localRenameLocs(SF, *info);
  if (RenameRanges.getLocations().empty())
    return true;

  return findSyntacticRenameRanges(SF, RenameRanges.getLocations(),
                                   /*NewName=*/StringRef(), RenameConsumer,
                                   DiagConsumer);
}
