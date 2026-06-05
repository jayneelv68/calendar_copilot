import AppKit

MainActor.assumeIsolated {
    let args = CommandLine.arguments
    let app = NSApplication.shared
    let delegate = AppDelegate()

    if args.contains("--demo") { delegate.demoMode = .flight }
    if args.contains("--demo-special") { delegate.demoMode = .special }
    if args.contains("--demo-welcome") { delegate.demoMode = .welcome }

    app.delegate = delegate
    app.run()
}
