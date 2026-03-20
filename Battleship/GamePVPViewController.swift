//
//  GamePVPViewController.swift
//  Battleship
//
//  Created by David Truong on 18/03/2026.
//

import UIKit

class GamePVPViewController: UIViewController {
    
    var tour: Int = 0
    var currentPlayerPlacing = 1
    var player1Board = Array(repeating: Array(repeating: 0, count: 10), count: 10)
    var player2Board = Array(repeating: Array(repeating: 0, count: 10), count: 10)
    
    var visualCells: [[UIButton]] = []
    var originalShipCenters: [UIView: CGPoint] = [:]
    var isShipHorizontal: [Int: Bool] = [:]
    var placedShipsTags: Set<Int> = []
    var currentShipPlacement: [Int: [(x: Int, y: Int)]] = [:]
    
    // Grille principal + dock bateaux
    let gridStackView = UIStackView()
    let dockStackView = UIStackView()
    
    // Listing des bateau à placer
    let shipsData: [(name: String, points: Int, height: CGFloat)] = [
        ("bateauDeuxPoints", 2, 60),
        ("bateauDeuxPoints", 2, 60),
        ("bateauTroisPoints", 3, 110),
        ("sousMarinTroisPoints", 3, 110),
        ("porteAvionsQuatrePoints", 4, 150)
    ]
    
    // Init de la grille et des bateaux
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGrid()
        setupShipsDock()
    }
    
    // Label de l'écran
    @IBOutlet weak var info_joueur: UIImageView!
    @IBOutlet weak var description_tour: UIImageView!
    @IBOutlet weak var bouton_suivant: UIButton!
    
    @IBAction func game(_ sender: Any) {
        if tour == 0 {
            resetShipsToDock()
            currentShipPlacement.removeAll()
            description_tour.image = UIImage(named: "positionement_texte")
            show_player()
        } else if tour == 1 {
            resetShipsToDock()
            currentShipPlacement.removeAll()
            description_tour.image = UIImage(named: "destruction_texte")
            DispawnDock()
            show_player()
            refreshGridForCurrentPlayer()
            bouton_suivant.isHidden = true
        } else {
            show_player()
            refreshGridForCurrentPlayer()
        }
    }
    
    // Gestion des noms de joueur
    func show_player(){
        if tour % 2 == 0 {
            info_joueur.image = UIImage(named: "joueur2")
            currentPlayerPlacing = 2
        } else {
            info_joueur.image = UIImage(named: "joueur1")
            currentPlayerPlacing = 1
        }
        tour += 1
    }
    
    // Etat de la grille
    @objc func cellTapped(_ sender: UIButton) {
        guard tour >= 2 else { return }
        
        let x = sender.tag % 10
        let y = sender.tag / 10
        
        var isHit = false
        var isValidShot = false
        
        if currentPlayerPlacing == 1 {
            if player2Board[y][x] == 2 || player2Board[y][x] == 3 {
                print("Case déjà ciblée !")
                return
            }
            
            isValidShot = true
            if player2Board[y][x] == 1 {
                print("Joueur 1 : Touché en X:\(x), Y:\(y) !")
                player2Board[y][x] = 2 //Bateau touché
                isHit = true
            } else {
                print("Joueur 1 : À l'eau...")
                
                
                player2Board[y][x] = 3 // Eau touchée
            }
        }
        else {
            if player1Board[y][x] == 2 || player1Board[y][x] == 3 {
                print("Case déjà ciblée !")
                return
            }
            
            isValidShot = true
            if player1Board[y][x] == 1 {
                print("Joueur 2 : Touché en X:\(x), Y:\(y) !")
                player1Board[y][x] = 2 // Bateau touché
                isHit = true
            } else {
                print("Joueur 2 : À l'eau...")
                player1Board[y][x] = 3 //Eau touchée
            }
        }
        guard isValidShot else { return }
        if isHit {
            sender.setImage(UIImage(named: "explosion"), for: .normal)
            if checkVictory() {
                handleVictory()
                return
            }
        } else {
            sender.backgroundColor = .white
            sender.alpha = 0.5
            sender.setImage(nil, for: .normal)
        }
        gridStackView.isUserInteractionEnabled = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.show_player()
            self.refreshGridForCurrentPlayer()
            self.gridStackView.isUserInteractionEnabled = true
        }
    }
    
    // Fonction pour remettre les visuels des bateaux à zéro pour le joueur suivant
    func resetShipsToDock() {
        for (ship, originalCenter) in originalShipCenters {
            UIView.animate(withDuration: 0.5) {
                ship.center = originalCenter
                ship.transform = .identity
            }
        }
    }
    
    // Clear du dock
    func DispawnDock(){
        UIView.animate(withDuration: 0.5, animations: {
            self.dockStackView.alpha = 0 // On le rend invisible
        }) { _ in
            self.dockStackView.isHidden = true
            for (ship, _) in self.originalShipCenters {
                ship.isHidden = true
            }
        }
    }
    
    // Fonction pour initialiser la grille
    func setupGrid() {
        gridStackView.axis = .vertical
        gridStackView.distribution = .fillEqually
        gridStackView.spacing = 1
        gridStackView.translatesAutoresizingMaskIntoConstraints = false
        gridStackView.backgroundColor = .white
        view.addSubview(gridStackView)
        
        NSLayoutConstraint.activate([
            gridStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gridStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            gridStackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.98),
            gridStackView.heightAnchor.constraint(equalTo: gridStackView.widthAnchor)
        ])
        
        for y in 0..<10 {
            let rowStack = UIStackView()
            rowStack.axis = .horizontal
            rowStack.distribution = .fillEqually
            rowStack.spacing = 1
            
            var rowButtons: [UIButton] = []
            
            for x in 0..<10 {
                let button = UIButton()
                button.setBackgroundImage(UIImage(named: "caseEau"), for: .normal)
                button.backgroundColor = .systemBlue
                
                button.tag = y * 10 + x
                button.addTarget(self, action: #selector(cellTapped(_:)), for: .touchUpInside)
                
                rowStack.addArrangedSubview(button)
                rowButtons.append(button)
            }
            gridStackView.addArrangedSubview(rowStack)
            visualCells.append(rowButtons)
        }
    }
    
    // Fonction pour initialiser les bateaux en dessous de la grille
    func setupShipsDock() {
        dockStackView.axis = .horizontal
        
        dockStackView.distribution = .equalSpacing
        dockStackView.alignment = .bottom
        dockStackView.spacing = 30
        
        dockStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dockStackView)
        
        NSLayoutConstraint.activate([
            dockStackView.topAnchor.constraint(equalTo: gridStackView.bottomAnchor),
            dockStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dockStackView.heightAnchor.constraint(equalToConstant: 140)
        ])
        
        let shipWidth: CGFloat = 25.0
        
        for (index, ship) in shipsData.enumerated() {
            let shipButton = UIButton()
            
            shipButton.setImage(UIImage(named: ship.name), for: .normal)
            shipButton.imageView?.contentMode = .scaleAspectFit
            shipButton.layer.cornerRadius = 5
            shipButton.tag = index
            
            isShipHorizontal[index] = false
            
            shipButton.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                shipButton.widthAnchor.constraint(equalToConstant: shipWidth),
                shipButton.heightAnchor.constraint(equalToConstant: ship.height)
            ])
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleShipPan(_:)))
            shipButton.addGestureRecognizer(panGesture)
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleShipTap(_:)))
            shipButton.addGestureRecognizer(tapGesture)
            
            shipButton.isUserInteractionEnabled = true
            dockStackView.addArrangedSubview(shipButton)
        }
    }
    
    // Fonction sur les bateaux pour tourner les bateaux
    @objc func handleShipTap(_ gesture: UITapGestureRecognizer) {
        guard let ship = gesture.view else { return }
        let tag = ship.tag
        removeShipFromBoard(tag: tag)
        
        UIView.animate(withDuration: 0.2) {
            if self.isShipHorizontal[tag] == true {
                ship.transform = .identity
                self.isShipHorizontal[tag] = false
            } else {
                ship.transform = CGAffineTransform(rotationAngle: -.pi / 2)
                self.isShipHorizontal[tag] = true
            }
        }
        if ship.superview == view {
            snapToNearestCell(ship: ship)
        }
    }
    
    
    @objc func handleShipPan(_ gesture: UIPanGestureRecognizer) {
        guard let ship = gesture.view else { return }
        switch gesture.state {
        case .began:
            removeShipFromBoard(tag: ship.tag)
            if let stackView = ship.superview as? UIStackView {
                let absoluteCenter = view.convert(ship.center, from: stackView)
                let absoluteBounds = ship.bounds
                
                view.addSubview(ship)
                ship.translatesAutoresizingMaskIntoConstraints = true
                ship.bounds = absoluteBounds
                ship.center = absoluteCenter
                
                originalShipCenters[ship] = absoluteCenter
            }
            view.bringSubviewToFront(ship)
            
        case .changed:
            let translation = gesture.translation(in: view)
            ship.center = CGPoint(x: ship.center.x + translation.x, y: ship.center.y + translation.y)
            gesture.setTranslation(.zero, in: view)
            
        case .ended, .cancelled:
            snapToNearestCell(ship: ship)
            
        default:
            break
        }
    }
    
    
    func snapToNearestCell(ship: UIView) {
        var closestCell: UIButton?
        var minDistance: CGFloat = .greatestFiniteMagnitude
        
        let isHorizontal = isShipHorizontal[ship.tag] ?? false
        
        let visualOriginX = isHorizontal ? (ship.center.x - ship.bounds.height / 2) : (ship.center.x - ship.bounds.width / 2)
        let visualOriginY = isHorizontal ? (ship.center.y - ship.bounds.width / 2) : (ship.center.y - ship.bounds.height / 2)
        let visualOrigin = CGPoint(x: visualOriginX, y: visualOriginY)
        
        for row in visualCells {
            for cell in row {
                let cellFrameInView = cell.convert(cell.bounds, to: view)
                
                let dx = visualOrigin.x - cellFrameInView.origin.x
                let dy = visualOrigin.y - cellFrameInView.origin.y
                let distance = hypot(dx, dy)
                
                if distance < minDistance {
                    minDistance = distance
                    closestCell = cell
                }
            }
        }
        
        if minDistance < 40, let targetCell = closestCell {
            let x = targetCell.tag % 10
            let y = targetCell.tag / 10
            let points = shipsData[ship.tag].points
            
            var isValidPlacement = false
            
            if isHorizontal {
                if x + points <= 10 { isValidPlacement = true }
            } else {
                if y + points <= 10 { isValidPlacement = true }
            }
            
            if isValidPlacement {
                for i in 0..<points {
                    let currentX = isHorizontal ? x + i : x
                    let currentY = isHorizontal ? y : y + i
                    
                    let boardToCheck = currentPlayerPlacing == 1 ? player1Board : player2Board
                    
                    if boardToCheck[currentY][currentX] == 1 {
                        isValidPlacement = false
                        print("Collision détectée en X:\(currentX), Y:\(currentY) ! Placement annulé.")
                        break
                    }
                }
            }
            
            if isValidPlacement {
                let targetFrame = targetCell.convert(targetCell.bounds, to: view)
                
                UIView.animate(withDuration: 0.2) {
                    if isHorizontal {
                        ship.center = CGPoint(
                            x: targetFrame.minX + (ship.bounds.height / 2),
                            y: targetFrame.midY
                        )
                    } else {
                        ship.center = CGPoint(
                            x: targetFrame.midX,
                            y: targetFrame.minY + (ship.bounds.height / 2)
                        )
                    }
                }
                
                var newOccupiedCells: [(x: Int, y: Int)] = []
                
                for i in 0..<points {
                    let currentX = isHorizontal ? x + i : x
                    let currentY = isHorizontal ? y : y + i
                    
                    if self.currentPlayerPlacing == 1 {
                        self.player1Board[currentY][currentX] = 1
                    } else {
                        self.player2Board[currentY][currentX] = 1
                    }
                    newOccupiedCells.append((x: currentX, y: currentY))
                }
                
                self.currentShipPlacement[ship.tag] = newOccupiedCells
                print("Sauvegardé : Bateau \(ship.tag) occupe \(newOccupiedCells)")
                
                return
            } else {
                print("Mauvais placement : Le bateau dépasse de la grille ou rentre en collision !")
            }
        }
        
        UIView.animate(withDuration: 0.3) {
            ship.transform = .identity
            self.isShipHorizontal[ship.tag] = false
            
            if let originalCenter = self.originalShipCenters[ship] {
                ship.center = originalCenter
            }
        }
    }
    
    func removeShipFromBoard(tag: Int) {
        if let occupiedCell = currentShipPlacement[tag] {
            for cell in occupiedCell {
                if currentPlayerPlacing == 1 {
                    player1Board[cell.y][cell.x] = 0
                } else {
                    player2Board[cell.y][cell.x] = 0
                }
            }
            currentShipPlacement.removeValue(forKey: tag)
        }
    }
    func refreshGridForCurrentPlayer() {
        for y in 0..<10 {
            for x in 0..<10 {
                let button = visualCells[y][x]
                
                let boardToDisplay = (currentPlayerPlacing == 1) ? player2Board : player1Board
                let cellState = boardToDisplay[y][x]
                
                button.backgroundColor = .systemBlue
                button.alpha = 1.0
                button.setImage(nil, for: .normal)
                button.setBackgroundImage(UIImage(named: "caseEau"), for: .normal)
                
                if cellState == 2 {
                    button.setImage(UIImage(named: "explosion"), for: .normal)
                } else if cellState == 3 {
                    button.backgroundColor = .white
                    button.alpha = 0.5
                }
            }
        }
    }
    
    func checkVictory() -> Bool {
        let boardToCheck = (currentPlayerPlacing == 1) ? player2Board : player1Board
        for row in boardToCheck {
            for cell in row {
                if cell == 1 {
                    return false
                }
            }
        }
        return true
    }
    
    func handleVictory() {
        print("VICTOIRE DU JOUEUR \(currentPlayerPlacing) !")
        
        gridStackView.isUserInteractionEnabled = false
        
        let alert = UIAlertController(
            title: "VICTOIRE !",
            message: "Le Joueur \(currentPlayerPlacing) a détruit toute la flotte ennemie bomboclaat",
            preferredStyle: .alert
        )
        
        let backToLobby = UIAlertAction(title: "Retour à l'accueil", style: .default) { _ in
            print("Retour à l'accueil")
            self.navigationController?.popToRootViewController(animated: true)
        }
        
        alert.addAction(backToLobby)
        
        present(alert, animated: true)
    }
    
}
