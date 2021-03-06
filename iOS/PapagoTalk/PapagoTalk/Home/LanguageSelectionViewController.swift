//
//  LanguageSelectionView.swift
//  PapagoTalk
//
//  Created by Byoung-Hwi Yoon on 2020/11/24.
//

import UIKit
import RxSwift
import RxCocoa

final class LanguageSelectionViewController: UIViewController {
    
    @IBOutlet private weak var pickerView: UIPickerView!
    @IBOutlet private weak var cancelButton: UIButton!
    @IBOutlet private weak var confirmButton: UIButton!
    
    private let userData: UserDataProviding
    var disposeBag = DisposeBag()
    var pickerViewObserver: BehaviorSubject<Language>
    
    init?(coder: NSCoder,
          userData: UserDataProviding,
          observer: BehaviorSubject<Language>) {
        self.userData = userData
        pickerViewObserver = observer
        super.init(coder: coder)
    }
    
    required init?(coder: NSCoder) {
        userData = UserDataProvider()
        pickerViewObserver = BehaviorSubject(value: Language.english)
        super.init(coder: coder)
    }
    
    override func viewDidLoad() {
        configurePickerView()
        bind()
        initializePickerView(at: userData.user.language.index)
        
        guard pickerView.subviews.count > 1 else {
            return
        }
        pickerView.subviews[1].backgroundColor = UIColor(red: 0.3, green: 0.3, blue: 1, alpha: 0)
        pickerView.subviews[1].layer.borderWidth = 2
        pickerView.subviews[1].layer.borderColor = UIColor(named: "PapagoBlue")?.cgColor
    }
    
    private func configurePickerView() {
        Observable.just(Language.allCases)
            .bind(to: pickerView.rx.itemTitles) { _, item in
                item.localizedText
            }
            .disposed(by: disposeBag)
    }
    
    private func bind() {
        cancelButton.rx.tap
            .asDriver()
            .drive(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        confirmButton.rx.tap
            .withLatestFrom(pickerView.rx.modelSelected(Language.self))
            .map { $0[0] }
            .do { [weak self] _ in
                self?.dismiss(animated: true, completion: nil)
            }
            .bind(to: pickerViewObserver)
            .disposed(by: disposeBag)
    }
    
    private func initializePickerView(at index: Int) {
        pickerView.selectRow(index, inComponent: 0, animated: true)
        pickerView.delegate?.pickerView?(pickerView, didSelectRow: index, inComponent: 0)
    }
}
