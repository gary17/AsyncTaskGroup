//
//  AsyncTaskGroup.swift
//  AsyncTaskGroup
//
//  Created by User on 8/24/20.
//  Copyright © 2020 R&F Consulting, Inc. All rights reserved.
//

import Foundation

public protocol AsyncTaskGroupStatus: AnyObject { // a class-only (pass-by-reference) protocol
	var isCancelled: Bool { get }
}

public class AsyncTaskGroup {
	public typealias Status = AsyncTaskGroupStatus
	
	//
	
	public enum Mnemonic {
		// plain "continue" is a reserved word, escape with backticks
		case `continue`, fail(with: Error)
	}

	public typealias CompletionHandler = (Mnemonic) -> Void
	public typealias Task = (Status, @escaping CompletionHandler) throws -> Void
	public typealias ErrorHandler = (Status, Error) -> Void
	
	//
	
	let qos: DispatchQoS.QoSClass
	let onError: ErrorHandler
	let tasks: [Task]
	
	//
	
	public static let defaultQoSClass: DispatchQoS.QoSClass = /* TODO: .userInitiated (?) */ .default

	public init(qos: DispatchQoS.QoSClass = defaultQoSClass, onError: @escaping ErrorHandler, /* array */ _ tasks: [Task]) {
		self.qos = qos
		self.onError = onError

		self.tasks = tasks
	}
	
	public convenience init(qos: DispatchQoS.QoSClass = defaultQoSClass, onError: @escaping ErrorHandler, /* variadic */ _ tasks: Task...) {
		self.init(qos: qos, onError: onError, tasks)
	}

	public func execute() {
		// cancellation logic is handled by individual tasks, the entire task group always gets executed anyway
		// always give all chain participants a chance to cancel gracefully
		_ = status.isCancelled

		if index < tasks.count {
			let task = tasks[index]

			DispatchQueue.global(qos: qos).async { [weak self] in
			
				guard let self_s = self else { return }
				
				do {
					try task(self_s.status) { [weak self] mnemonic in
					
						guard let self_s = self else { return }

						switch mnemonic
						{
							case .fail(let error):
								self_s.onError(self_s.status, error)
							
							case .continue:
								self_s.index = self_s.index + 1
								self_s.execute()
						}
					}
				}
				catch {
					self_s.onError(self_s.status, error)
				}
			}
			
			// dispatched
		}
	}

	public func cancelAllTasks() {
		if status.isCancelled == false {
			// TODO: do not allow canceling when already canceled?
			status.isCancelled = true
		}
	}

	// MARK: - private
	
	private class AsyncTaskGroupStatusObject: Status {
		var isCancelled: Bool {
			// thread safety: https://www.raywenderlich.com/148513/grand-central-dispatch-tutorial-swift-3-part-1

			get {
				var oldValue: Bool!
				
				// dispatch synchronously to perform the read

				queue.sync {
					oldValue = self._isCanceled
				}

				return oldValue
			}
			
			set {
				// dispatch the write operation asynchronously with a barrier

				queue.async(flags: .barrier) {
					self._isCanceled = newValue
				}
			}
		}
		
		// MARK: - private
		
		private let queue = DispatchQueue(label: "com.rfcons.asynctaskgroup.status.iscanceled", attributes: .concurrent)
		private var _isCanceled: Bool = false
	}

	private var index: Int = 0
	
	private let status = AsyncTaskGroupStatusObject()
}
