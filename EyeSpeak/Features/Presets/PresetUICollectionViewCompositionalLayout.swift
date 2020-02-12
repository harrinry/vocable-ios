//
//  PresetUICollectionViewFlowLayout.swift
//  EyeSpeak
//
//  Created by Jesse Morgan on 2/4/20.
//  Copyright © 2020 WillowTree. All rights reserved.
//

import UIKit

class PresetUICollectionViewCompositionalLayout: UICollectionViewCompositionalLayout {
    
    private static let totalHeight: CGFloat = 834.0
    private static let totalWidth: CGFloat = 1112.0
    
    var dataSource: UICollectionViewDiffableDataSource<PresetsViewController.Section, PresetsViewController.ItemWrapper>? {
        self.collectionView?.dataSource as? UICollectionViewDiffableDataSource<PresetsViewController.Section, PresetsViewController.ItemWrapper>
    }
    
    override func initialLayoutAttributesForAppearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = super.initialLayoutAttributesForAppearingItem(at: itemIndexPath)
        // Make animation only happen for preset items
        guard let item = dataSource?.itemIdentifier(for: itemIndexPath), case PresetsViewController.ItemWrapper.presetItem(_) = item else {
            return attr
        }
        attr?.transform = CGAffineTransform(translationX: 0, y: 500.0)
        return attr
    }
    
    override func finalLayoutAttributesForDisappearingItem(at itemIndexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        let attr = super.finalLayoutAttributesForDisappearingItem(at: itemIndexPath)
        // Make animation only happen for preset items
        guard let item = dataSource?.itemIdentifier(for: itemIndexPath), case PresetsViewController.ItemWrapper.presetItem(_) = item else {
            return attr
        }
        attr?.transform = CGAffineTransform(translationX: 0, y: 500.0)
        return attr
    }
    
    // MARK: - Section Layouts
    
    static func topBarSectionLayout() -> NSCollectionLayoutSection {
        let redoButtonItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(116.0 / 240.0),
                                               heightDimension: .fractionalHeight(1.0)))
        
        let keyboardButtonItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(116.0 / 240.0),
                                               heightDimension: .fractionalHeight(1.0)))
        
        let subitems = [redoButtonItem, keyboardButtonItem]
        
        let containerGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalHeight(64.0 / totalHeight)),
            subitems: subitems)
        containerGroup.interItemSpacing = .fixed(8)
        
        let section = NSCollectionLayoutSection(group: containerGroup)
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 256, bottom: 0, trailing: 256)
        
        return section
    }
    
    static func textFieldSectionLayout() -> NSCollectionLayoutSection {
        let textFieldItem = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalHeight(1.0)))
        
        let subitems = [textFieldItem]
        
        let containerGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalHeight(86.0 / totalHeight)),
            subitems: subitems)
        containerGroup.interItemSpacing = .flexible(0)
        containerGroup.edgeSpacing = NSCollectionLayoutEdgeSpacing(leading: .flexible(400), top: .fixed(0), trailing: .flexible(400), bottom: .fixed(0))
        
        let section = NSCollectionLayoutSection(group: containerGroup)
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 32, bottom: 0, trailing: 32)
        
        return section
    }
    
    static func categoriesSectionLayout() -> NSCollectionLayoutSection {
        let category1Item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(262.0 / 1048.0),
                                               heightDimension: .fractionalHeight(1.0)))
        let category2Item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(262.0 / 1048.0),
                                               heightDimension: .fractionalHeight(1.0)))
        let category3Item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(262.0 / 1048.0),
                                               heightDimension: .fractionalHeight(1.0)))
        let category4Item = NSCollectionLayoutItem(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(262.0 / 1048.0),
                                               heightDimension: .fractionalHeight(1.0)))
        
        let subitems = [category1Item, category2Item, category3Item, category4Item]
        
        let containerGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalHeight(137.0 / totalHeight)),
            subitems: subitems)
        containerGroup.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        let section = NSCollectionLayoutSection(group: containerGroup)
        
        let backgroundDecoration = NSCollectionLayoutDecorationItem.background(elementKind: "CategorySectionBackground")
        backgroundDecoration.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)
        
        section.decorationItems = [backgroundDecoration]
        section.contentInsets = NSDirectionalEdgeInsets(top: 16, leading: 32, bottom: 16, trailing: 32)
        return section
    }
        
    static func presetsSectionLayout() -> NSCollectionLayoutSection {
        let presetItem = NSCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(339.0 / totalWidth),
                                                                                   heightDimension: .fractionalHeight(1.0)))
        
        let rowGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalHeight(1.0)),
            subitem: presetItem, count: 3)
        rowGroup.interItemSpacing = .fixed(16)
        
        let containerGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalHeight(464.0 / totalHeight)),
            subitem: rowGroup, count: 3)
        containerGroup.interItemSpacing = .fixed(16)
        containerGroup.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 32, bottom: 0, trailing: 32)
        
        let section = NSCollectionLayoutSection(group: containerGroup)
        section.interGroupSpacing = 0
        section.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        section.orthogonalScrollingBehavior = .groupPaging
        
        let headerFooterSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(44))
        let footer = NSCollectionLayoutBoundarySupplementaryItem(layoutSize: headerFooterSize, elementKind: UICollectionView.elementKindSectionFooter, alignment: .bottom)
        footer.extendsBoundary = true
        footer.pinToVisibleBounds = true
        section.boundarySupplementaryItems = [footer]
        
        return section
    }
    
    // MARK: Keyboard Layout
    
    //                                 +-------+
    // Triple keyboard key group, i.e. | Q W E |
    //                                 +-------+
    static let tripleKeyItemFractionalWidth = 339.0 / totalWidth
    static let tripleKeyItem = keyboardCollectionLayoutItem(
        layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(tripleKeyItemFractionalWidth),
                                           heightDimension: .fractionalHeight(1.0)))
    
    //                                    +---------+
    // Quadruple keyboard key group, i.e. | U I O P |
    //                                    +---------+
    static let quadrupleKeyItemFractionalWidth: CGFloat = 4.0 / 10.0
    static let quadrupleKeyItem = keyboardCollectionLayoutItem(
        layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(quadrupleKeyItemFractionalWidth),
                                           heightDimension: .fractionalHeight(1.0)))
    
    static func keyboardSectionLayout() -> NSCollectionLayoutSection {
        let keyboardContainerGroup = NSCollectionLayoutGroup.vertical(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalHeight(400 / totalHeight)),
            subitems: [topRowGroup(), middleRowGroup(), bottomRowGroup()])
        
        let section = NSCollectionLayoutSection(group: keyboardContainerGroup)
        section.contentInsets = .init(top: 0, leading: 32, bottom: 0, trailing: 32)
        
        return section
    }
    
    private static func topRowGroup() -> NSCollectionLayoutGroup {
        let multiKeyFractionalWidth: CGFloat = 6.0 / 10.0
        
        assert(multiKeyFractionalWidth + quadrupleKeyItemFractionalWidth == 1.0,
               "The top keyboard layout does not fill 100% of its container group's width")
        
        let multiKeyGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(multiKeyFractionalWidth),
                                               heightDimension: .fractionalHeight(1.0)),
            subitem: tripleKeyItem, count: 2)
        
        return NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalHeight(1.0 / 3.0)),
            subitems: [multiKeyGroup, quadrupleKeyItem])
    }
    
    private static func middleRowGroup() -> NSCollectionLayoutGroup {
        let middleLeadingItem = keyboardCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(tripleKeyItemFractionalWidth),
                                                                                                heightDimension: .fractionalHeight(1.0)))
        middleLeadingItem.edgeSpacing = .init(leading: .flexible(16), top: nil, trailing: nil, bottom: nil)
        
        let middleTrailingItem = keyboardCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(tripleKeyItemFractionalWidth),
                                                                                                 heightDimension: .fractionalHeight(1.0)))
        middleTrailingItem.edgeSpacing = .init(leading: nil, top: nil, trailing: .flexible(16), bottom: nil)
        
        return NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1),
                                               heightDimension: .fractionalHeight(1.0 / 3.0)),
            subitems: [middleLeadingItem, tripleKeyItem, middleTrailingItem])
    }
    
    private static func bottomRowGroup() -> NSCollectionLayoutGroup {
        let smallKeyGroupFractionalWidth = 1.0 - tripleKeyItemFractionalWidth - quadrupleKeyItemFractionalWidth
        
        assert(smallKeyGroupFractionalWidth + tripleKeyItemFractionalWidth + quadrupleKeyItemFractionalWidth == 1.0,
               "The bottom keyboard layout does not fill 100% of its container group's width")
        
        let smallKeyItem = keyboardCollectionLayoutItem(layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0 / 2.0), heightDimension: .fractionalHeight(1.0)))
        
        let smallBottomKeyGroup = NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(smallKeyGroupFractionalWidth), heightDimension: .fractionalHeight(1.0)),
            subitems: [smallKeyItem, smallKeyItem])
        
        return NSCollectionLayoutGroup.horizontal(
            layoutSize: NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalHeight(1.0 / 3.0)),
            subitems: [tripleKeyItem, quadrupleKeyItem, smallBottomKeyGroup])
    }
    
    private static func keyboardCollectionLayoutItem(layoutSize: NSCollectionLayoutSize) -> NSCollectionLayoutItem {
        let item = NSCollectionLayoutItem(layoutSize: layoutSize)
        item.contentInsets = .init(top: 4, leading: 4, bottom: 4, trailing: 4)
        return item
    }
}
