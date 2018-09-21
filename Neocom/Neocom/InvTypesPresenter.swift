//
//  InvTypesPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures
import CloudData
import CoreData
import Expressible

class InvTypesPresenter: TreePresenter {
	typealias View = InvTypesViewController
	typealias Interactor = InvTypesPresenterInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.FetchedResultsNamedSection<Tree.Item.InvType>>
	
	weak var view: View!
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view.tableView.register([Prototype.TreeHeaderCell.default,
								 Prototype.InvTypeCell.charge,
								 Prototype.InvTypeCell.default,
								 Prototype.InvTypeCell.module,
								 Prototype.InvTypeCell.ship])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
		
		switch view.input {
		case let .category(category)?:
			view.title = category.categoryName
		case let .group(group)?:
			view.title = group.groupName
		default:
			break
		}

	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		
		guard let input = view.input else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		let treeController = view.treeController
		
		var filter: Predictable
		
		switch input {
		case let .category(category):
			filter = \SDEInvType.group?.category == category
		case let .group(group):
			filter = \SDEInvType.group == group
		default:
			filter = true
		}
		
		if view.parent is UISearchController {
			let string = searchString ?? ""
			filter = string.count > 2 ? filter && (\SDEInvType.typeName).caseInsensitive.contains(string) : false
			searchString = nil
		}
		
		
		
		return Services.sde.performBackgroundTask { context -> Presentation in
			let controller = context.managedObjectContext
				.from(SDEInvType.self)
				.filter(filter)
				.sort(by: \SDEInvType.metaGroup?.metaGroupID, ascending: true)
				.sort(by: \SDEInvType.metaLevel, ascending: true)
				.sort(by: \SDEInvType.typeName, ascending: true)
				.select([
					Self.as(NSManagedObjectID.self, name: "objectID"),
					(\SDEInvType.dgmppItem?.requirements).as(NSManagedObjectID.self, name: "requirements"),
					(\SDEInvType.dgmppItem?.shipResources).as(NSManagedObjectID.self, name: "shipResources"),
					(\SDEInvType.dgmppItem?.damage).as(NSManagedObjectID.self, name: "damage"),
					(\SDEInvType.metaGroup?.metaGroupName).as(String.self, name: "metaGroupName")])
				.fetchedResultsController(sectionName: (\SDEInvType.metaGroup?.metaGroupName).as(String.self, name: "metaGroupName"))
			try controller.performFetch()
			return Presentation(controller, treeController: treeController)
		}
	}
	
	private var searchString: String?
	
	func updateSearchResults(with string: String) {
		if searchString == nil {
			searchString = string
			if let loading = loading {
				loading.then(on: .main) { [weak self] _ in
					self?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) {
						self?.view.present($0, animated: false)
					}
				}
			}
			else {
				reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak self] in
					self?.view.present($0, animated: false)
				}
			}
		}
		else {
			searchString = string
		}
	}
	
	
}
