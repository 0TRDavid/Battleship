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
    
    let gridStackView = UIStackView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGrid()
        setupShipsDock()
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
                button.backgroundColor = .systemBlue // Pour bien voir la grille si l'image est absente
                
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
            dockStackView.topAnchor.constraint(equalTo: gridStackView.bottomAnchor, constant: 30),
            dockStackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dockStackView.heightAnchor.constraint(equalToConstant: 200)
        ])
        
        let shipsData: [(name: String, points: Int, height: CGFloat)] = [
            ("bateauDeuxPoints", 2, 60),
            ("bateauDeuxPoints", 2, 60),
            ("bateauTroisPoints", 3, 110),
            ("sousMarinTroisPoints", 3, 110),
            ("porteAvionsQuatrePoints", 4, 150)
        ]
        
        //let unitHeight: CGFloat = 30.0
        let shipWidth: CGFloat = 25.0
        
        for (index, ship) in shipsData.enumerated() {
            let shipButton = UIButton()
            
            shipButton.setImage(UIImage(named: ship.name), for: .normal)
            shipButton.imageView?.contentMode = .scaleAspectFit
            shipButton.layer.cornerRadius = 5
            shipButton.tag = index
            

            shipButton.translatesAutoresizingMaskIntoConstraints = false
            
            NSLayoutConstraint.activate([
                shipButton.widthAnchor.constraint(equalToConstant: shipWidth),
                shipButton.heightAnchor.constraint(equalToConstant: ship.height)
            ])
            
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleShipPan(_:)))
            shipButton.addGestureRecognizer(panGesture)
            shipButton.isUserInteractionEnabled = true
            
            dockStackView.addArrangedSubview(shipButton)
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
        
        let shipOrigin = ship.frame.origin
        
        for row in visualCells {
            for cell in row {
                let cellFrameInView = cell.convert(cell.bounds, to: view)
                let cellOrigin = cellFrameInView.origin
                
                let dx = shipOrigin.x - cellOrigin.x
                let dy = shipOrigin.y - cellOrigin.y
                let distance = sqrt(dx * dx + dy * dy)
                
                if distance < minDistance {
                    minDistance = distance
                    closestCell = cell
                }
            }
        }
        
        if minDistance < 40, let targetCell = closestCell {
            let targetFrame = targetCell.convert(targetCell.bounds, to: view)
            
            UIView.animate(withDuration: 0.2) {
                ship.frame.origin.x = targetFrame.midX - (ship.frame.width / 2)
                
                ship.frame.origin.y = targetFrame.minY
            }
            
            let x = targetCell.tag % 10
            let y = targetCell.tag / 10
            print("Bateau \(ship.tag) placé en X:\(x), Y:\(y)")
            
        } else {
            UIView.animate(withDuration: 0.3) {
                if let originalCenter = self.originalShipCenters[ship] {
                    ship.center = originalCenter
                }
            }
        }
    }
    
    @objc func cellTapped(_ sender: UIButton) {
        let x = sender.tag % 10
        let y = sender.tag / 10
        
        print("Le joueur a tiré en X: \(x), Y: \(y)")
        
        if gameBoard[y][x] == 1 {
            sender.backgroundColor = .orange // Touché !
        } else {
            sender.backgroundColor = .white // Dans l'eau...
            sender.alpha = 0.5
        }
    }
}
