//
//  GamePVPViewController.swift
//  Battleship
//
//  Created by David Truong on 18/03/2026.
//

import UIKit

class GamePVPViewController: UIViewController {
    
    // Ma grille logique (Données) + stockage des bouttons
    var gameBoard = Array(repeating: Array(repeating: 0, count: 10), count: 10)
    var visualCells: [[UIButton]] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupGrid()
    }

    func setupGrid() {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fillEqually
        stackView.spacing = 1
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.backgroundColor = .white
        view.addSubview(stackView)

        // Contraintes pour que la grille soit carrée et centrée
        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stackView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.9),
            stackView.heightAnchor.constraint(equalTo: stackView.widthAnchor)
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
                
                // ASTUCE : On identifie le bouton par sa position
                // On stocke x et y dans le "tag" (ex: x=2, y=3 -> tag=32)
                button.tag = y * 10 + x
                
                button.addTarget(self, action: #selector(cellTapped(_:)), for: .touchUpInside)
                
                rowStack.addArrangedSubview(button)
                rowButtons.append(button)
            }
            stackView.addArrangedSubview(rowStack)
            visualCells.append(rowButtons)
        }
    }

    @objc func cellTapped(_ sender: UIButton) {
        let x = sender.tag % 10
        let y = sender.tag / 10
        
        print("Le joueur a tiré en X: \(x), Y: \(y)")
        
        // Logique / Etat de de la case
        if gameBoard[y][x] == 1 {
            sender.backgroundColor = .orange // Touché !
        } else {
            sender.backgroundColor = .white // Dans l'eau...
            sender.alpha = 0.5
        }
    }
    
    
}
