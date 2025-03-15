import Foundation
import SpriteKit

/// 敵AIの制御を行うクラス
class EnemyAI {
    /// AIの難易度
    enum Difficulty {
        /// 簡単
        case easy
        /// 普通
        case normal
        /// 難しい
        case hard
    }
    
    /// 難易度
    let difficulty: Difficulty
    
    /// 現在の餌の量
    private var foodAmount: Int = 30
    
    /// 餌の増加速度（1秒間に増える量）
    private var foodIncreaseRate: Double = 1.0
    
    /// 次の猫を召喚するまでの時間（秒）
    private var timeUntilNextCat: TimeInterval
    
    /// 次の猫の行動を決めるまでの時間（秒）
    private var timeUntilNextAction: TimeInterval = 0
    
    /// 参照するゲームシーン
    private weak var gameScene: GameScene?
    
    /// 初期化
    /// - Parameters:
    ///   - difficulty: AIの難易度
    ///   - gameScene: ゲームシーンへの参照
    init(difficulty: Difficulty, gameScene: GameScene) {
        self.difficulty = difficulty
        self.gameScene = gameScene
        
        // 難易度に応じた初期値を設定
        switch difficulty {
        case .easy:
            timeUntilNextCat = 15.0
            foodIncreaseRate = 0.8
        case .normal:
            timeUntilNextCat = 10.0
            foodIncreaseRate = 1.0
        case .hard:
            timeUntilNextCat = 7.0
            foodIncreaseRate = 1.2
        }
    }
    
    /// 更新処理
    /// - Parameter deltaTime: 経過時間
    func update(deltaTime: TimeInterval) {
        // 餌を増やす
        foodAmount += Int(foodIncreaseRate * deltaTime)
        
        // 猫の召喚タイマー処理
        timeUntilNextCat -= deltaTime
        if timeUntilNextCat <= 0 {
            summonRandomCat()
            resetSummonTimer()
        }
        
        // 猫の行動決定タイマー処理
        timeUntilNextAction -= deltaTime
        if timeUntilNextAction <= 0 {
            controlCats()
            resetActionTimer()
        }
    }
    
    /// 猫の召喚タイマーをリセット
    private func resetSummonTimer() {
        switch difficulty {
        case .easy:
            timeUntilNextCat = 12.0 + Double.random(in: 0...6)
        case .normal:
            timeUntilNextCat = 8.0 + Double.random(in: 0...4)
        case .hard:
            timeUntilNextCat = 5.0 + Double.random(in: 0...4)
        }
    }
    
    /// 猫の行動決定タイマーをリセット
    private func resetActionTimer() {
        timeUntilNextAction = 3.0 + Double.random(in: 0...2)
    }
    
    /// ランダムな種類の猫を召喚
    private func summonRandomCat() {
        guard let gameScene = gameScene else { return }
        
        // 召喚する猫の種類をランダムに選択
        let catTypes = CatType.allCases
        let randomType = catTypes.randomElement() ?? .normal
        
        // 猫の召喚コスト
        let cost = randomType.summonCost
        
        // 餌が足りるかチェック
        if foodAmount >= cost {
            foodAmount -= cost
            
            // 召喚位置を決定（敵の陣地からランダムに）
            if let spawnTile = findEnemyOwnedTile() {
                // 猫のサイズ
                let catSize = CGSize(width: 30, height: 30)
                
                // 猫を召喚
                if let cat = GameManager.shared.summonCat(
                    catType: randomType,
                    position: spawnTile.position,
                    owner: .enemy,
                    size: catSize
                ) {
                    // シーンに追加
                    gameScene.addChild(cat)
                    
                    // 行動モードをランダムに設定
                    cat.currentMode = Bool.random() ? .attack : .collect
                }
            }
        }
    }
    
    /// 全ての敵の猫の行動を制御
    private func controlCats() {
        // 敵の猫のリストを取得
        let enemyCats = GameManager.shared.enemyCats
        
        for cat in enemyCats {
            // 難易度に応じて戦略的思考を変える
            switch difficulty {
            case .easy:
                simpleRandomBehavior(for: cat)
            case .normal:
                normalBehavior(for: cat)
            case .hard:
                strategicBehavior(for: cat)
            }
        }
    }
    
    /// 簡単な難易度の猫の行動（ランダム）
    /// - Parameter cat: 行動を決定する猫
    private func simpleRandomBehavior(for cat: CatNode) {
        // ランダムなタイルを選択
        guard let randomTile = randomTile() else { return }
        
        // そのタイルに向かって移動
        cat.moveToTile(randomTile)
    }
    
    /// 普通の難易度の猫の行動
    /// - Parameter cat: 行動を決定する猫
    private func normalBehavior(for cat: CatNode) {
        // 猫の行動モードに応じて目的地を選択
        switch cat.currentMode {
        case .collect:
            // 餌を集めるなら敵の陣地か中立地帯を選択
            if let tile = findPreferredTileForCollection() {
                cat.moveToTile(tile)
            }
        case .attack:
            // 攻撃するならプレイヤーの陣地を選択
            if let tile = findPlayerOwnedTile() {
                cat.moveToTile(tile)
            } else {
                // プレイヤーの陣地がない場合は中立地帯を選択
                if let tile = findNeutralTile() {
                    cat.moveToTile(tile)
                }
            }
        }
    }
    
    /// 難しい難易度の猫の行動（戦略的）
    /// - Parameter cat: 行動を決定する猫
    private func strategicBehavior(for cat: CatNode) {
        // 猫の種類と行動モードに応じて戦略的に動く
        
        switch cat.catType {
        case .normal:
            // バランス型はバランス良く行動
            if Double.random(in: 0...1) < 0.5 {
                cat.currentMode = .collect
                if let tile = findPreferredTileForCollection() {
                    cat.moveToTile(tile)
                }
            } else {
                cat.currentMode = .attack
                if let tile = findBestTileToAttack() {
                    cat.moveToTile(tile)
                }
            }
            
        case .attack:
            // 攻撃型は攻撃を優先
            cat.currentMode = .attack
            if let tile = findBestTileToAttack() {
                cat.moveToTile(tile)
            }
            
        case .collector:
            // 収集型は収集を優先
            cat.currentMode = .collect
            if let tile = findPreferredTileForCollection() {
                cat.moveToTile(tile)
            }
        }
    }
    
    /// ランダムなタイルを取得
    /// - Returns: ランダムに選ばれたタイル
    private func randomTile() -> TileNode? {
        let grid = GameManager.shared.grid
        guard !grid.isEmpty else { return nil }
        
        let randomRow = Int.random(in: 0..<grid.count)
        guard randomRow < grid.count, !grid[randomRow].isEmpty else { return nil }
        
        let randomCol = Int.random(in: 0..<grid[randomRow].count)
        guard randomCol < grid[randomRow].count else { return nil }
        
        return grid[randomRow][randomCol]
    }
    
    /// 敵の所有するタイルをランダムに取得
    /// - Returns: 敵の所有するタイル
    private func findEnemyOwnedTile() -> TileNode? {
        let grid = GameManager.shared.grid
        
        var enemyTiles: [TileNode] = []
        
        for row in grid {
            for tile in row {
                if tile.owner == .enemy {
                    enemyTiles.append(tile)
                }
            }
        }
        
        return enemyTiles.randomElement()
    }
    
    /// プレイヤーの所有するタイルをランダムに取得
    /// - Returns: プレイヤーの所有するタイル
    private func findPlayerOwnedTile() -> TileNode? {
        let grid = GameManager.shared.grid
        
        var playerTiles: [TileNode] = []
        
        for row in grid {
            for tile in row {
                if tile.owner == .player {
                    playerTiles.append(tile)
                }
            }
        }
        
        return playerTiles.randomElement()
    }
    
    /// 中立のタイルをランダムに取得
    /// - Returns: 中立のタイル
    private func findNeutralTile() -> TileNode? {
        let grid = GameManager.shared.grid
        
        var neutralTiles: [TileNode] = []
        
        for row in grid {
            for tile in row {
                if tile.owner == .neutral {
                    neutralTiles.append(tile)
                }
            }
        }
        
        return neutralTiles.randomElement()
    }
    
    /// 収集に適したタイルを取得
    /// - Returns: 収集に適したタイル
    private func findPreferredTileForCollection() -> TileNode? {
        // 敵の陣地を優先的に選ぶ
        if let enemyTile = findEnemyOwnedTile() {
            return enemyTile
        }
        
        // 敵の陣地がない場合は中立地帯を選ぶ
        return findNeutralTile()
    }
    
    /// 攻撃に最適なタイルを取得
    /// - Returns: 攻撃に最適なタイル
    private func findBestTileToAttack() -> TileNode? {
        let grid = GameManager.shared.grid
        
        // プレイヤーの陣地に隣接するタイル優先度リスト
        var priorityTiles: [TileNode] = []
        
        // プレイヤータイルに隣接する敵または中立タイルを探す
        for y in 0..<grid.count {
            for x in 0..<grid[y].count {
                let tile = grid[y][x]
                
                // 自分の陣地は対象外
                if tile.owner == .enemy {
                    continue
                }
                
                // 隣接するタイルをチェック
                let adjacentPositions = [
                    (x: x+1, y: y),
                    (x: x-1, y: y),
                    (x: x, y: y+1),
                    (x: x, y: y-1)
                ]
                
                for adjPos in adjacentPositions {
                    if adjPos.y >= 0 && adjPos.y < grid.count &&
                        adjPos.x >= 0 && adjPos.x < grid[adjPos.y].count {
                        let adjTile = grid[adjPos.y][adjPos.x]
                        if adjTile.owner == .player {
                            priorityTiles.append(tile)
                            break
                        }
                    }
                }
            }
        }
        
        // 優先度の高いタイルがあればそれを返す
        if let priorityTile = priorityTiles.randomElement() {
            return priorityTile
        }
        
        // なければプレイヤーのタイルをランダムに返す
        return findPlayerOwnedTile()
    }
}