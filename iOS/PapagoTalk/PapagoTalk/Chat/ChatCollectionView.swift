//
//  ChatCollectionView.swift
//  PapagoTalk
//
//  Created by Byoung-Hwi Yoon on 2020/12/12.
//

import UIKit

class ChatCollectionView: UICollectionView {
        func scrollToLast() {
            superview?.layoutIfNeeded()
            let newY = contentSize.height - bounds.height
            setContentOffset(CGPoint(x: 0, y: newY < 0 ? 0 : newY), animated: false)
        }
    
        func keyboardWillShow(keyboardHeight: CGFloat) {
            guard let superview = superview else {
                return
            }
            var offset = contentOffset
            var yOffSet = keyboardHeight - superview.safeAreaInsets.bottom
            let maxYOffSet = contentSize.height - bounds.height
            yOffSet = yOffSet > maxYOffSet ? maxYOffSet : yOffSet
            offset.y += yOffSet
            setContentOffset(offset, animated: false)
        }
    
        func keyboardWillHide(keyboardHeight: CGFloat) {
            guard let superview = superview else {
                return
            }
            var offset = contentOffset
            let yOffSet = keyboardHeight - superview.safeAreaInsets.bottom
            offset.y -= yOffSet
            offset.y = offset.y < 0 ? 0 : offset.y
            setContentOffset(offset, animated: false)
        }
}
