// Copyright 2022-2023 Chartboost, Inc.
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file.

import Foundation

/// A list of externally configurable properties pertaining to the partner SDK that can be retrieved and set by publishers.
@objc public class HyperMXAdapterConfiguration: NSObject {

    /// HyprMX requires publishers to provide a unique user identifier
    @objc public static var userID: String? = nil
}
