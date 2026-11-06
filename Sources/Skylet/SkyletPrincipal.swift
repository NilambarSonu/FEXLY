//
//  SkyletPrincipal.swift
//  Fexly
//

import Foundation
import DroppyKit

/// The class Droppy's loader instantiates, named in the bundle's `NSPrincipalClass`.
/// It exists only to make one droplet instance, keeping initialization lightweight.
@objc(FexlyPrincipal)
public final class FexlyPrincipal: NSObject, DropletPrincipal {
    public override init() { super.init() }

    @MainActor public func makeDroplet() -> AnyObject { FexlyDroplet() }
}

@objc(SkyletPrincipal)
public final class SkyletPrincipal: NSObject, DropletPrincipal {
    public override init() { super.init() }

    @MainActor public func makeDroplet() -> AnyObject { FexlyDroplet() }
}

