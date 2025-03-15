import Foundation

/// 猫のタイプを定義する列挙型
enum CatType: String, CaseIterable {
    /// バランス型の猫
    case normal
    /// 攻撃特化型の猫
    case attack
    /// 餌収集特化型の猫
    case collector
    
    /// 猫のタイプに応じた攻撃力を返す
    var attackPower: Double {
        switch self {
        case .normal: return 1.0
        case .attack: return 2.0
        case .collector: return 0.5
        }
    }
    
    /// 猫のタイプに応じた収集力を返す
    var collectPower: Double {
        switch self {
        case .normal: return 1.0
        case .attack: return 0.5
        case .collector: return 2.0
        }
    }
    
    /// 猫のタイプに応じた召喚コスト（餌の量）を返す
    var summonCost: Int {
        switch self {
        case .normal: return 10
        case .attack: return 15
        case .collector: return 12
        }
    }
    
    /// 猫のタイプに応じた表示名を返す
    var displayName: String {
        switch self {
        case .normal: return "普通猫"
        case .attack: return "攻撃猫"
        case .collector: return "収集猫"
        }
    }
}