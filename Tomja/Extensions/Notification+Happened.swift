//
//  Notification+Happened.swift
//  Tomja
//
//  Created by Tom Knighton on 23/12/2025.
//
import Foundation

extension NSNotification.Name {
    public static var deviceUpdated = NSNotification.Name("tomjaDeviceUpdated")
    public static var deviceFailFlash = NSNotification.Name("tomjaDeviceFailFlash")
    public static var deviceFailClear = NSNotification.Name("tomjaDeviceFailClear")
    public static var deviceFailImage = NSNotification.Name("tomjaDeviceFailImage")
}
