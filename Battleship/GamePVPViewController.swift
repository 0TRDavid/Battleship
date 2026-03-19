//
//  GamePVPViewController.swift
//  Battleship
//
//  Created by David Truong on 18/03/2026.
//

import UIKit

class GamePVPViewController: UIViewController {
    
    var gameBoard = Array(repeating: Array(repeating: 0, count: 10), count: 10)
    var visualCells: [[UIButton]] = []
    var originalShipCenters: [UIView: CGPoint] = [:]
    var tour: Int = 0
    
    var isShipHorizontal: [Int: Bool] = [:]
    
    let gridStackView = UIStackView()
    
    let shipsData: [(name: String, points: Int, height: CGFloat)] = [
        ("bateauDeuxPoints", 2, 60),
        ("bateauDeuxPoints", 2, 60),
        ("bateauTroisPoints", 3, 110),
        ("sousMarinTroisPoints", 3, 110),
        ("porteAvionsQuatrePoints", 4, 150)
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGrid()
        setupShipsDock()
    }
    // Label de l'écran
    @IBOutlet weak var info_joueur: UIImageView!
    @IBOutlet weak var description_tour: UIImageView!
    
    @IBAction func game(_ sender: Any) {
        if tour == 0 {
            description_tour.image = UIImage(named: "positionement_texte")
            info_joueur.image = UIImage(named: "joueur2")
            tour += 1
        } else {
            description_tour.image = UIImage(named: "destruction_texte")
            if tour % 2 == 0 {
                info_joueur.image = UIImage(named: "joueur1")
            } else {
                info_joueur.image = UIImage(named: "joueur2")
            }
            tour += 1
        }
    }
    
    func setupGrid() {
        gridStackView.axis = .vertical
        gridStackView.distribution = .fillEqually
        gridStackView.spacing = 1
        gridStackView.translatesAutoresizingMaskIntoConstraints = false
        gridStackView.backgroundColor = .white
        view.addSubview(gridStackView)
        
        NSLayoutConstraint.activate([
            gridStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            gridStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor, constant: -50),
            gridStackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
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
    
    func setupShipsDock() {
        let dockStackView = UIStackView()
        dockStackView.axis = .horizontal
        
        dockStackView.distribution = .equalSpacing
        dockStackView.alignment = .bottom
        dockStackView.spacing = 20
        
        dockStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(dockStackView)
        
        NSLayoutConstraint.activate([
            dockStackView.topAnchor.constraint(equalTo: gridStackView.bottomAnchor, constant: 20),
            dockStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dockStackView.heightAnchor.constraint(equalToConstant: 150)
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
        
    @objc func handleShipTap(_ gesture: UITapGestureRecognizer) {
        guard let ship = gesture.view else { return }
        let tag = ship.tag
        
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
                print("Bon placement : Bateau \(ship.tag) en X:\(x), Y:\(y) (Horizontal: \(isHorizontal))")
                return
            } else {
                print("Mauvais placement : Le bateau dépasse de la grille !")
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
    
    @objc func cellTapped(_ sender: UIButton) {
        let x = sender.tag % 10
        let y = sender.tag / 10
        
        if gameBoard[y][x] == 1 {
            sender.backgroundColor = .orange
        } else {
            sender.backgroundColor = .white
            sender.alpha = 0.5
        }
    }
}
