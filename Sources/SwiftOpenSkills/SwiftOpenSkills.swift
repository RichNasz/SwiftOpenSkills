/// SwiftOpenSkills — Native Swift support for the open Agent Skills standard.
///
/// Use ``SkillStore`` as the primary entry point:
/// ```swift
/// let store = SkillStore()
/// try await store.load()                    // scan standard locations
/// // or:
/// try await store.load(.directory(myURL), .standard)
///
/// let catalog = await store.catalog()
/// print(catalog.systemPromptSection())      // embed in your system prompt
/// ```
///
/// For integration with SwiftOpenResponsesDSL, import `SwiftOpenSkillsResponses`.
/// For integration with SwiftChatCompletionsDSL, import `SwiftOpenSkillsChat`.
