//
//  StringExtension.swift
//  Chats
//
//  Created by Danil Zvyagintsev on 8/7/14.
//  Copyright (c) 2014 Acani Inc. All rights reserved.
//

import Foundation

extension String {
    var initials: String {
    get {
        return "".join(self.componentsSeparatedByString(" ").map {
            (component: String) -> String in
            return component.substringToIndex(advance(component.startIndex, 1))
            })
    }
    }
}