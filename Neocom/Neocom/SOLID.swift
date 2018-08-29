//
//  SOLID.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

protocol View: class {
	associatedtype Presenter: Neocom.Presenter
	var presenter: Presenter! {get set}
	
	associatedtype Input = Void
	var input: Input? {get set}
}

protocol Interactor: class {
	associatedtype Presenter: Neocom.Presenter
	var presenter: Presenter! {get set}
	var cache: Cache! {get set}
	var sde: SDE! {get set}
	var storage: Storage! {get set}
	
	init(presenter: Presenter)
	func configure() -> Void
	func api(cachePolicy: URLRequest.CachePolicy) -> API
}

protocol Presenter: class {
	associatedtype View: Neocom.View
	associatedtype Interactor: Neocom.Interactor
	var view: View! {get set}
	var interactor: Interactor! {get set}
	
	init(view: View)

	func configure() -> Void
	func viewWillAppear(_ animated: Bool) -> Void
	func viewDidAppear(_ animated: Bool) -> Void
	func viewWillDisappear(_ animated: Bool) -> Void
	func viewDidDisappear(_ animated: Bool) -> Void
	func applicationWillEnterForeground() -> Void
	func beginTask(totalUnitCount: Int64, indicator: ProgressTask.Indicator) -> ProgressTask
	func beginTask(totalUnitCount: Int64) -> ProgressTask
}

extension View where Input == Void {
	var input: Input? {
		get { return nil }
		set {}
	}
}

extension Presenter {
	func configure() -> Void {
		interactor.configure()
	}
	
	func viewWillAppear(_ animated: Bool) -> Void {
	}
	
	func viewDidAppear(_ animated: Bool) -> Void {
	}
	
	func viewWillDisappear(_ animated: Bool) -> Void {
	}
	
	func viewDidDisappear(_ animated: Bool) -> Void {
	}
	
	func applicationWillEnterForeground() {
		
	}
}

extension Presenter {
	func beginTask(totalUnitCount: Int64, indicator: ProgressTask.Indicator) -> ProgressTask {
		return ProgressTask(progress: Progress(totalUnitCount: totalUnitCount), indicator: indicator)
	}

}

extension Presenter where View: UIViewController {
	func beginTask(totalUnitCount: Int64) -> ProgressTask {
		return beginTask(totalUnitCount: totalUnitCount, indicator: .progressBar(view))
	}
	
}

extension Presenter where View: UIView {
	func beginTask(totalUnitCount: Int64) -> ProgressTask {
		return beginTask(totalUnitCount: totalUnitCount, indicator: .progressBar(view))
	}
	
}

extension Interactor {
	func api(cachePolicy: URLRequest.CachePolicy) -> API {
		return APIClient(account: storage.viewContext.currentAccount, cachePolicy: cachePolicy, cache: cache, sde: sde)
	}

	func configure() {

	}
}

protocol ContentProviderView: View where Presenter: ContentProviderPresenter {
	func present(_ content: Presenter.Presentation) -> Future<Void>
	func fail(_ error: Error) -> Void
}

protocol ContentProviderPresenter: Presenter where View: ContentProviderView, Interactor: ContentProviderInteractor, Presentation == View.Presenter.Presentation {
	associatedtype Presentation
	var content: Interactor.Content? {get set}
	var presentation: Presentation? {get set}
	var isLoading: Bool {get set}
	
	func reload(cachePolicy: URLRequest.CachePolicy) -> Future<Void>
	func presentation(for content: Interactor.Content) -> Future<Presentation>
	func didChange(content: Interactor.Content) -> Void
}

protocol ContentProviderInteractor: Interactor where Presenter: ContentProviderPresenter {
	associatedtype Content = Void
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content>
	func isExpired(_ content: Content) -> Bool
}

extension ContentProviderPresenter {
	
	func reload(cachePolicy: URLRequest.CachePolicy) -> Future<Void> {
		let task = beginTask(totalUnitCount: 3)

		return task.performAsCurrent(withPendingUnitCount: 1) {
			interactor.load(cachePolicy: cachePolicy).then { [weak self] content -> Future<Void> in
				guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
				return DispatchQueue.main.async {
					task.performAsCurrent(withPendingUnitCount: 1) {
						strongSelf.presentation(for: content).then(on: .main) { presentation -> Future<Void> in
							guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
							strongSelf.content = content
							strongSelf.presentation = presentation
							return task.performAsCurrent(withPendingUnitCount: 1) {
								strongSelf.view.present(presentation)
							}
						}
					}
				}
			}.catch(on: .main) { [weak self] error in
				guard let strongSelf = self else {return}
				strongSelf.view.fail(error)
			}
		}
	}
	
	func didChange(content: Interactor.Content) -> Void {
		self.presentation(for: content).then(on: .main) { [weak self] presentation -> Future<Void> in
			guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
			strongSelf.content = content
			strongSelf.presentation = presentation
			return strongSelf.view.present(presentation)
		}
	}
}

extension ContentProviderPresenter where Interactor.Content == Void {
	var content: Void? {
		get { return ()}
		set {}
	}
}

extension ContentProviderInteractor where Content: CachedValueProtocol {
	
	func isExpired(_ content: Content) -> Bool {
		guard let cachedUntil = content.cachedUntil else {return true}
		return cachedUntil < Date()
	}
}

extension ContentProviderPresenter {
	func reloadIfNeeded() {
		guard !isLoading else {return}
		if let content = content, presentation != nil, !interactor.isExpired(content) {
			return
		}
		else {
			reload(cachePolicy: .useProtocolCachePolicy).finally(on: .main) { [weak self] in
				self?.isLoading = false
			}
		}
	}
	
	func viewWillAppear(_ animated: Bool) -> Void {
		reloadIfNeeded()
	}
	
	func applicationWillEnterForeground() -> Void {
		reloadIfNeeded()
	}
}

extension ContentProviderInteractor where Content == Void {
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Void> {
		return .init(())
	}
	
	func isExpired(_ content: Void) -> Bool {
		return false
	}
}

extension ContentProviderPresenter where Interactor.Content: CachedValueProtocol {
	
	func reload(cachePolicy: URLRequest.CachePolicy) -> Future<Void> {
		let task = beginTask(totalUnitCount: 3)
		
		return task.performAsCurrent(withPendingUnitCount: 1) {
			interactor.load(cachePolicy: cachePolicy).then { [weak self] content -> Future<Void> in
				guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
				return DispatchQueue.main.async {
					task.performAsCurrent(withPendingUnitCount: 1) {
						strongSelf.presentation(for: content).then(on: .main) { presentation -> Future<Void> in
							guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
							strongSelf.content = content
							strongSelf.presentation = presentation
							
							strongSelf.content?.observer?.handler = { newValue in
								self?.didChange(content: newValue)
							}

							return task.performAsCurrent(withPendingUnitCount: 1) {
								strongSelf.view.present(presentation)
							}

						}
					}
				}
				}.catch(on: .main) { [weak self] error in
					guard let strongSelf = self else {return}
					strongSelf.view.fail(error)
			}
		}
	}
	
}
