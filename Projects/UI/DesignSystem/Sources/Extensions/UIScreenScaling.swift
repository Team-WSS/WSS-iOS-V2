//
//  UIScreenScaling.swift
//  DesignSystem
//
//  Created by Seoyeon Choi on 12/8/25.
//  Copyright © 2025 kr.websoso.app. All rights reserved.
//

import Foundation
import UIKit

extension CGFloat {
    var adjustedWidth: CGFloat {
        let ratio: CGFloat = UIScreen.main.bounds.width / 375
        return self * ratio
    }

    var adjustedHeight: CGFloat {
        let ratio: CGFloat = UIScreen.main.bounds.height / 812
        return self * ratio
    }
}

extension Double {
    var adjustedWidth: Double {
        let ratio: Double = Double(UIScreen.main.bounds.width / 375)
        return self * ratio
    }

    var adjustedHeight: Double {
        let ratio: Double = Double(UIScreen.main.bounds.height / 812)
        return self * ratio
    }
}

extension Int {
    var adjustedWidth: CGFloat {
        return CGFloat(self).adjustedWidth
    }

    var adjustedHeight: CGFloat {
        return CGFloat(self).adjustedHeight
    }
}
