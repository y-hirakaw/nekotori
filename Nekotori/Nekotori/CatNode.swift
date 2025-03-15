import SpriteKit

/// 猫キャラクターを表現するノード
class CatNode: SKSpriteNode {
    /// 猫の行動モード
    enum ActionMode {
        /// 餌を収集する
        case collect
        /// 陣地を攻める
        case attack
    }
    
    /// 猫の種類
    let catType: CatType
    
    /// 猫の所有者
    let owner: TileNode.Owner
    
    /// 現在の行動モード
    var currentMode: ActionMode = .collect
    
    /// 対象のタイル
    var targetTile: TileNode?
    
    /// 移動速度 (ポイント/秒)
    var moveSpeed: CGFloat = 100.0
    
    /// 収集/攻撃の進行度
    private var actionProgress: TimeInterval = 0
    
    /// 1回の行動にかかる時間（秒）
    var actionDuration: TimeInterval {
        switch currentMode {
        case .collect: return 2.0 / CGFloat(catType.collectPower)
        case .attack: return 3.0 / CGFloat(catType.attackPower)
        }
    }
    
    /// 初期化
    /// - Parameters:
    ///   - catType: 猫の種類
    ///   - owner: 猫の所有者
    ///   - size: 猫のサイズ
    init(catType: CatType, owner: TileNode.Owner, size: CGSize) {
        self.catType = catType
        self.owner = owner
        
        // 猫の種類と所有者に応じた色を設定
        let color: UIColor
        switch owner {
        case .player:
            color = .blue
        case .enemy:
            color = .red
        default:
            color = .gray
        }
        
        super.init(texture: nil, color: color, size: size)
        
        setupCat()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// 猫の初期設定
    private func setupCat() {
        // 猫の形を楕円で表現
        let catShape = SKShapeNode(ellipseOf: CGSize(width: size.width * 0.8, height: size.height * 0.8))
        catShape.fillColor = color
        catShape.strokeColor = .black
        catShape.lineWidth = 1.0
        addChild(catShape)
        
        // 猫の種類を表すラベル
        let typeLabel = SKLabelNode(text: catType.displayName.prefix(1).uppercased())
        typeLabel.fontSize = 14
        typeLabel.fontColor = .white
        typeLabel.verticalAlignmentMode = .center
        addChild(typeLabel)
        
        // 行動モードを示す目印
        updateModeIndicator()
        
        // 物理ボディの設定
        physicsBody = SKPhysicsBody(circleOfRadius: size.width / 2)
        physicsBody?.isDynamic = true
        physicsBody?.affectedByGravity = false
        physicsBody?.allowsRotation = false
        physicsBody?.categoryBitMask = owner == .player ? 0x1 : 0x2
    }
    
    /// 行動モードの表示を更新
    private func updateModeIndicator() {
        // 既存のインジケータを削除
        children.filter { $0.name == "modeIndicator" }.forEach { $0.removeFromParent() }
        
        // 新しいインジケータを追加
        let indicator = SKShapeNode(circleOfRadius: 5)
        indicator.name = "modeIndicator"
        indicator.position = CGPoint(x: size.width / 2 - 5, y: size.height / 2 - 5)
        
        switch currentMode {
        case .collect:
            indicator.fillColor = .yellow  // 収集モードは黄色
        case .attack:
            indicator.fillColor = .red     // 攻撃モードは赤
        }
        
        addChild(indicator)
    }
    
    /// 行動モードを切り替える
    func toggleMode() {
        currentMode = currentMode == .collect ? .attack : .collect
        updateModeIndicator()
    }
    
    /// 指定したタイルに向かって移動する
    /// - Parameter tile: 目標タイル
    func moveToTile(_ tile: TileNode) {
        targetTile = tile
        
        // タイルの位置へ移動するアクションを作成
        let moveAction = SKAction.move(to: tile.position, duration: TimeInterval(distance(to: tile.position) / moveSpeed))
        
        // 移動完了時のコールバック
        let completionAction = SKAction.run { [weak self] in
            self?.arrivedAtTarget()
        }
        
        // アクションを実行
        run(SKAction.sequence([moveAction, completionAction]))
    }
    
    /// 目標位置までの距離を計算
    /// - Parameter position: 目標位置
    /// - Returns: 距離
    private func distance(to position: CGPoint) -> CGFloat {
        let dx = position.x - self.position.x
        let dy = position.y - self.position.y
        return sqrt(dx * dx + dy * dy)
    }
    
    /// 目標タイルに到着した時の処理
    private func arrivedAtTarget() {
        // 行動の開始
        actionProgress = 0
    }
    
    /// 毎フレームの更新処理
    /// - Parameter deltaTime: 前回の更新からの経過時間
    func update(deltaTime: TimeInterval) {
        guard let targetTile = targetTile else { return }
        
        // 目標地点についていたら行動を進める
        if distance(to: targetTile.position) < 5 {
            actionProgress += deltaTime
            
            let progressPercent = CGFloat(actionProgress / actionDuration)
            
            switch currentMode {
            case .collect:
                // 餌集めのアニメーション表現などを行う
                break
                
            case .attack:
                // 陣地の占領を進める
                if owner != .neutral {
                    targetTile.progressCapture(amount: progressPercent * 0.05, newOwner: owner)
                }
            }
        }
    }
}