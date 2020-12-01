//
//  ChatViewController.swift
//  PapagoTalk
//
//  Created by 송민관 on 2020/11/25.
//

import UIKit
import ReactorKit
import RxCocoa
import RxGesture

final class ChatViewController: UIViewController, StoryboardView {
    
    @IBOutlet private weak var inputBarTextView: UITextView!
    @IBOutlet private weak var inputBarTextViewHeight: NSLayoutConstraint!
    @IBOutlet private weak var chatCollectionView: UICollectionView!
    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet private weak var chatDrawerButton: UIBarButtonItem!
    @IBOutlet private weak var bottomConstraint: NSLayoutConstraint!
    
    private weak var chatDrawerViewController: ChatDrawerViewController!
    private var chatDrawerWidth: CGFloat!
    private var visualEffectView: UIVisualEffectView!
    private var runningAnimations = [UIViewPropertyAnimator]()
    private var animationProgressWhenInterrupted = CGFloat.zero
    
    var disposeBag = DisposeBag()
    weak var coordinator: MainCoordinator?
    
    init?(coder: NSCoder, reactor: ChatViewReactor) {
        super.init(coder: coder)
        self.reactor = reactor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bind()
        bindKeyboard()
    }
    
    func bind(reactor: ChatViewReactor) {
        self.rx.viewWillAppear
            .map { _ in Reactor.Action.subscribeNewMessages }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        sendButton.rx.tap
            .withLatestFrom(inputBarTextView.rx.text)
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .map { Reactor.Action.sendMessage($0) }
            .do(afterNext: { [weak self] _ in
                self?.inputBarTextView.text = nil
                self?.scrollToLastMessage()
            })
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        chatDrawerButton.rx.tap
            .map { Reactor.Action.chatDrawerButtonTapped }
            .bind(to: reactor.action)
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.messageBox.messages }
            .bind(to: chatCollectionView.rx.items) { [weak self] (_, row, element) in
                guard let cell = self?.configureChatMessageCell(at: row, with: element) else {
                    return UICollectionViewCell()
                }
                return cell
            }
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.sendResult }
            .asObservable()
            .do(afterNext: { [weak self] isSuccess in
                guard isSuccess else {
                    return
                }
                self?.scrollToLastMessage()
            })
            .subscribe()
            .disposed(by: disposeBag)
        
        reactor.state.map { $0.drawerState }
            .distinctUntilChanged()
            .do { [weak self] _ in
                if !(self?.runningAnimations.isEmpty ?? true) {
                    self?.runningAnimations.removeAll()
                }
            }
            .subscribe(onNext: { [weak self] in
                ($0) ? self?.configureChatDrawer() : self?.configureAnimation(state: .closed, duration: 0.5)
            })
            .disposed(by: disposeBag)
    }
    
    private func bind() {
        chatCollectionView.rx.setDelegate(self)
            .disposed(by: disposeBag)
        
        inputBarTextView.rx.text
            .orEmpty
            .compactMap { [weak self] text in
                self?.calculateTextViewHeight(with: text)
            }
            .asObservable()
            .distinctUntilChanged()
            .bind(to: inputBarTextViewHeight.rx.constant)
            .disposed(by: disposeBag)
    }
    
    private func calculateTextViewHeight(with text: String) -> CGFloat {
        let size = inputBarTextView.sizeThatFits(CGSize(width: inputBarTextView.bounds.size.width,
                                                        height: CGFloat.greatestFiniteMagnitude))
        return min(Constant.inputBarTextViewMaxHeight, size.height)
    }
    
    private func configureChatMessageCell(at row: Int, with element: Message) -> UICollectionViewCell {
        guard let cell = chatCollectionView.dequeueReusableCell(withReuseIdentifier: element.type.identifier,
                                                                for: IndexPath(row: row, section: .zero)) as? MessageCell else {
            return UICollectionViewCell()
        }
        cell.configureMessageCell(message: element)
        return cell
    }
    
    private func scrollToLastMessage() {
        let newY = chatCollectionView.contentSize.height - chatCollectionView.bounds.height
        chatCollectionView.setContentOffset(CGPoint(x: 0, y: newY < 0 ? 0 : newY), animated: true)
    }
    
    // MARK: - configure ChatDrawer
    
    private func configureChatDrawer() {
        guard chatDrawerViewController == nil else {
            return
        }
        configureVisualEffectView()

        chatDrawerViewController =
            storyboard?.instantiateViewController(identifier: ChatDrawerViewController.identifier)
        addChild(chatDrawerViewController)
        view.addSubview(chatDrawerViewController.view)
        
        chatDrawerWidth = (view.frame.width * 3) / 4
        chatDrawerViewController.view.frame = CGRect(x: view.frame.width,
                                                     y: .zero,
                                                     width: chatDrawerWidth,
                                                     height: view.frame.height)
        chatDrawerViewController.view.clipsToBounds = true
        bindChatDrawerGesture()
        configureAnimation(state: .opened, duration: 0.9)
    }
    
    private func configureVisualEffectView() {
        visualEffectView = UIVisualEffectView()
        visualEffectView.frame = view.frame
        view.addSubview(visualEffectView)
    }
    
    private func bindChatDrawerGesture() {
        chatDrawerViewController
            .view.rx.panGesture()
            .subscribe(onNext: { [weak self] in
                self?.chatDrawerPanned(recognizer: $0)
            })
            .disposed(by: disposeBag)
        
        /*
         let chatDrawerButtonTap = chatDrawerButton.rx.tap.map { _ in return () }
         let view: Observable<Void> = visualEffectView.rx.tapGesture().when(.recognized).map { _ in return () }
         
         Observable.of(chatDrawerButtonTap, view).merge()
         
         visualEffectView.rx.tapGesture()
             .when(.recognized)
             .map { $0.touchesBegan(.init(), with: .init()) }
             .bind(to: chatDrawerButton.rx.tap.asControlEvent())
             .disposed(by: disposeBag)
         
        */
    }
    
    // MARK: - ChatDrawer Animation
    
    private func configureAnimation(state: ChatDrawerState, duration: TimeInterval) {
        guard runningAnimations.isEmpty else {
            DispatchQueue.main.async { [weak self] in
                self?.runningAnimations.removeAll()
                self?.configureAnimation(state: state, duration: duration)
            }
            return
        }
        
        let frameAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) { [weak self] in
            guard let self = self, let chatDrawer = self.chatDrawerViewController else {
                return
            }
            switch state {
            case .opened:
                chatDrawer.view.frame.origin.x = self.view.frame.width - self.chatDrawerWidth
            case .closed:
                chatDrawer.view.frame.origin.x = self.view.frame.width
            }
        }
        frameAnimator.addCompletion { [weak self] _ in
            self?.runningAnimations.removeAll()
            guard let chatDrawer = self?.chatDrawerViewController, state == .closed else {
                return
            }
            chatDrawer.dismiss(animated: false, completion: nil)
            self?.chatDrawerViewController = nil
        }
        frameAnimator.startAnimation()
        runningAnimations.append(frameAnimator)
        
        let blurAnimator = UIViewPropertyAnimator(duration: duration, dampingRatio: 1) { [weak self] in
            guard let visualEffectView = self?.visualEffectView else {
                return
            }
            switch state {
            case .opened:
                visualEffectView.effect = UIBlurEffect(style: .dark)
                visualEffectView.alpha = 0.3
            case .closed:
                visualEffectView.effect = nil
            }
        }
        blurAnimator.startAnimation()
        runningAnimations.append(blurAnimator)
    }
    
    // MARK: - ChatDrawer PanGesture
    
    private func chatDrawerPanned(recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            startInteractiveTransition(state: .closed, duration: 0.5)
        case .changed:
            let translation = recognizer.translation(in: chatDrawerViewController.view)
            updateInteractiveTransition(fractionCompleted: translation.x / chatDrawerWidth)
        case .ended:
            continueInteractiveTransition()
        default:
            break
        }
    }
    
    private func startInteractiveTransition(state: ChatDrawerState, duration: TimeInterval) {
        if runningAnimations.isEmpty {
            configureAnimation(state: state, duration: 0.9)
        }
        runningAnimations.forEach({
            $0.pauseAnimation()
            animationProgressWhenInterrupted = $0.fractionComplete
        })
    }
    
    private func updateInteractiveTransition(fractionCompleted: CGFloat) {
        runningAnimations.forEach({
            $0.fractionComplete = fractionCompleted + animationProgressWhenInterrupted
        })
    }
    
    private func continueInteractiveTransition() {
        runningAnimations.forEach({
            $0.continueAnimation(withTimingParameters: nil, durationFactor: 0)
        })
    }
}

extension ChatViewController: KeyboardProviding {
    private func bindKeyboard() {
        tapToDissmissKeyboard
            .drive()
            .disposed(by: disposeBag)
        
        keyboardWillShow
            .drive(onNext: { [weak self] keyboardFrame in
                guard let self = self else {
                    return
                }
                self.bottomConstraint.constant = keyboardFrame.height - self.view.safeAreaInsets.bottom
                UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut) {
                    self.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
        
        keyboardWillHide
            .drive(onNext: { [weak self] _ in
                self?.bottomConstraint.constant = 0
                UIView.animate(withDuration: 0.6, delay: 0, options: .curveEaseInOut) {
                    self?.view.layoutIfNeeded()
                }
            })
            .disposed(by: disposeBag)
    }
}

// TODO: Rx로 수정
extension ChatViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        CGSize(width: collectionView.frame.width, height: 40)
    }
}