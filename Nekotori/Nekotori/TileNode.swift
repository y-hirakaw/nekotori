import SpriteKit

/// フィールド上の1マスを表すタイルノード
class TileNode: SKSpriteNode {
    /// タイルの所有者
    enum Owner: Int {
        /// 中立
        case neutral = 0
        /// プレイヤー
        case player = 1
        /// 敵
        case enemy = 2
    }
    
    /// 占領進行度 (0.0-1.0)
    private(set) var captureProgress: CGFloat = 0.0
    
    /// タイルの座標位置（グリッド上のインデックス）
    let gridPosition: (x: Int, y: Int)
    
    /// タイルの所有者
    private(set) var owner: Owner = .neutral {
        didSet {
            updateAppearance()
        }
    }
    
    /// 餌の生産量ボーナス
    var foodProductionBonus: Double = 1.0
    
    /// 初期化
    /// - Parameters:
    ///   - gridPosition: グリッド上の位置
    ///   - size: タイルのサイズ
    init(gridPosition: (x: Int, y: Int), size: CGSize) {
        self.gridPosition = gridPosition
        super.init(texture: nil, color: .lightGray, size: size)
        
        setupTile()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// タイルの初期設定
    private func setupTile() {
        // タイルの外枠を設定
        let border = SKShapeNode(rectOf: size)
        border.strokeColor = .darkGray
        border.lineWidth = 1.0
        addChild(border)
        
        // タイルの名前を設定
        name = "tile_\(gridPosition.x)_\(gridPosition.y)"
        
        // 初期状態の見た目を適用
        updateAppearance()
    }
    
    /// タイルの外観を更新
    private func updateAppearance() {
        switch owner {
        case .neutral:
            color = .lightGray
        case .player:
            color = .blue
        case .enemy:
            color = .red
        }
    }
    
    /// 占領を進める
    /// - Parameters:
    ///   - amount: 進行度の増分
    ///   - newOwner: 占領しようとしているプレイヤー
    /// - Returns: 占領が完了したかどうか
    @discardableResult
    func progressCapture(amount: CGFloat, newOwner: Owner) -> Bool {
        // すでに同じ所有者なら何もしない
        if owner == newOwner {
            captureProgress = 1.0
            return false
        }
        
        captureProgress += amount
        
        // 占領進行度を視覚的に表示
        updateCaptureProgress()
        
        // 占領完了
        if captureProgress >= 1.0 {
            captureProgress = 0.0
            owner = newOwner
            return true
        }
        
        return false
    }
    
    /// 占領の進行状況を視覚的に表示
    private func updateCaptureProgress() {
        // 既存の進行インジケータがあれば削除
        children.filter { $0.name == "captureIndicator" }.forEach { $0.removeFromParent() }
        
        // 進行中のみインジケータを表示
        if captureProgress > 0 && captureProgress < 1.0 {
            let indicator = SKShapeNode(rectOf: CGSize(width: size.width * captureProgress, height: 5))
            indicator.fillColor = .yellow
            indicator.strokeColor = .yellow
            indicator.position = CGPoint(x: 0, y: -size.height/2 + 5)
            indicator.name = "captureIndicator"
            addChild(indicator)
        }
    }
}