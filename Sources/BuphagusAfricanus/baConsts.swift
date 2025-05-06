//
//  baConsts.swift
//  BuphagusAfricanus
//

import Foundation


public enum baConsts {

    // 默认主窗口尺寸
    public static let defaultMainWindowWidth: CGFloat = 400
    public static let defaultMainWindowHeight: CGFloat = 600

    // 默认调试窗口尺寸
    public static let defaultDebugWindowWidth: CGFloat = 400

    // debugwindow 和 mainwindow 的间隔
    public static let debugWindowMainWindowSpacing: CGFloat = 0

    public static let debugWindowInsideToMainWindowSpacing: CGFloat = 10

    // 吸附配置
    public static let snapDistanceOutside: CGFloat = 50  // 外部吸附距离
    public static let snapDistanceInside: CGFloat = 150  // 内部吸附距离
    public static let dragStartThreshold: CGFloat = 0  // 拖动开始阈值
}
