import CoreServices
import Foundation

let appIdentifier = "local.pierrevannier.MarkdownPreview" as NSString
let markdownContentTypes = [
    "com.unknown.md",
    "net.daringfireball.markdown",
    "public.markdown",
    "dyn.ah62d4rv4ge8043a",
    "dyn.ah62d4rv4ge8042pwrrwg875s",
    "dyn.ah62d4rv4ge8043dts71a",
    "dyn.ah62d4rv4ge80445e",
    "dyn.ah62d4rv4ge80445er2",
    "dyn.ah62d4rv4ge8043d1r2",
    "dyn.ah62d4rv4ge81e5pe",
]

var failed = false
for contentType in markdownContentTypes {
    let status = LSSetDefaultRoleHandlerForContentType(
        contentType as NSString,
        LSRolesMask.viewer,
        appIdentifier
    )

    if status != noErr {
        fputs("Failed to set Viewer handler for \(contentType): \(status)\n", stderr)
        failed = true
    }
}

if failed {
    exit(1)
}
