import AppKit
import ApplicationServices
import CometransCore

public final class LiveClipboardService: ClipboardServicing {
    public init() {}

    public func checkAccessibilityPermissions(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt]
        return AXIsProcessTrustedWithOptions(options as CFDictionary)
    }

    public func copySelectedText() -> String? {
        if let selectedText = selectedTextFromAccessibility() {
            return selectedText
        }

        let originalValue = NSPasteboard.general.string(forType: .string)

        NSPasteboard.general.clearContents()
        waitForHotKeyModifiersToClear()
        simulate(keyCode: 0x08)
        Thread.sleep(forTimeInterval: 0.1)

        guard let copiedText = NSPasteboard.general.string(forType: .string) else {
            restorePasteboard(with: originalValue)
            return nil
        }

        return copiedText
    }

    public func pasteText(_ text: String) {
        let originalValue = NSPasteboard.general.string(forType: .string)

        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        simulate(keyCode: 0x09)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.restorePasteboard(with: originalValue)
        }
    }

    private func restorePasteboard(with value: String?) {
        guard let value else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(value, forType: .string)
    }

    private func selectedTextFromAccessibility() -> String? {
        if let app = NSWorkspace.shared.frontmostApplication {
            let appElement = AXUIElementCreateApplication(app.processIdentifier)
            if let text = selectedText(in: appElement) {
                return text
            }
        }

        let systemElement = AXUIElementCreateSystemWide()
        return selectedText(in: systemElement)
    }

    private func selectedText(in element: AXUIElement) -> String? {
        if let text = stringAttribute(kAXSelectedTextAttribute, from: element), !text.isEmpty {
            return text
        }

        var focusedValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXFocusedUIElementAttribute as CFString,
            &focusedValue
        ) == .success, let focusedElement = focusedValue else {
            return nil
        }

        guard CFGetTypeID(focusedElement) == AXUIElementGetTypeID() else {
            return nil
        }

        let focusedAXElement = focusedElement as! AXUIElement
        guard let text = stringAttribute(kAXSelectedTextAttribute, from: focusedAXElement), !text.isEmpty else {
            return nil
        }

        return text
    }

    private func stringAttribute(_ attribute: String, from element: AXUIElement) -> String? {
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, attribute as CFString, &value) == .success else {
            return nil
        }

        return value as? String
    }

    private func waitForHotKeyModifiersToClear() {
        let deadline = Date().addingTimeInterval(0.35)
        let modifiers: CGEventFlags = [.maskCommand, .maskShift, .maskControl, .maskAlternate]

        while Date() < deadline {
            if CGEventSource.flagsState(.hidSystemState).intersection(modifiers).isEmpty {
                return
            }

            Thread.sleep(forTimeInterval: 0.01)
        }
    }

    private func simulate(keyCode: CGKeyCode) {
        let source = CGEventSource(stateID: .hidSystemState)
        let commandDown = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: true)
        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        let commandUp = CGEvent(keyboardEventSource: source, virtualKey: 0x37, keyDown: false)

        commandDown?.flags = .maskCommand
        keyDown?.flags = .maskCommand
        keyUp?.flags = .maskCommand

        commandDown?.post(tap: .cghidEventTap)
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
        commandUp?.post(tap: .cghidEventTap)
    }
}
