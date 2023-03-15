// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command file_length implicit_return prefer_self_in_static_references

// MARK: - Strings

// swiftlint:disable function_parameter_count identifier_name line_length type_body_length
internal extension R {
  enum Text {
  /// API Key
    internal static let apiKey = Text.tr("Localizable", "api_key", fallback: "API Key")
  /// Please add API Key first
    internal static let apiKeyDesc = Text.tr("Localizable", "api_key_desc", fallback: "Please add API Key first")
  /// Cancel
    internal static let cancel = Text.tr("Localizable", "cancel", fallback: "Cancel")
  /// Done
    internal static let done = Text.tr("Localizable", "done", fallback: "Done")
  /// Please enter your question
    internal static let enterYourQuestion = Text.tr("Localizable", "enter_your_question", fallback: "Please enter your question")
  /// Loading
    internal static let loading = Text.tr("Localizable", "loading", fallback: "Loading")
  /// Your API key
    internal static let yourApiKey = Text.tr("Localizable", "your_api_key", fallback: "Your API key")
  }
}

// swiftlint:enable function_parameter_count identifier_name line_length type_body_length

// MARK: - Implementation Details

extension R.Text {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg..., fallback value: String) -> String {
    let format = BundleToken.bundle.localizedString(forKey: key, value: value, table: table)
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
