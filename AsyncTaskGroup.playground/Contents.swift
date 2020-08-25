import Foundation

enum /* namespace */ Config
{
	// "JSONPlaceholder is a free online REST API that you can use whenever you need some fake data."
	static func endpointURL(forObjectId id: UInt) -> String { "https://jsonplaceholder.typicode.com/todos/\(id)" }
}

enum Failure: Error
{
	case unknown, httpError(code: Int?, message: String?)
}

// Xcode playground execution thread vs. task group execution thread
let semaphore = DispatchSemaphore(value: /* yes: zero, not one */ 0)

class ViewControllerSimulacrum
{
	func executeAsyncTasks()
	{
		// a (loquacious) UI handler

		let failureHandler: AsyncTaskGroup.ErrorHandler = { /* a capture list */ [weak self] (status, error) in

			// always attempt to signal the semaphore
			_ = status.isCancelled
			
			if let self_s = self
			{
				// e.g., present UIAlertController
				_ = error
				_ = self_s
			}
			
			// the async task group is complete, allow the simulacrum to be destroyed
			semaphore.signal()
		}
		
		let task1: AsyncTaskGroup.Task = { status, next in
			
			guard status.isCancelled == false else
			{
				next(.continue) // give other chain participants a chance to cancel gracefully
				return
			}

			let endpointURL = Config.endpointURL(forObjectId: 1)

			let request = URLRequest(url: URL(string: endpointURL)!)
			let task = URLSession.shared.dataTask(with: request) { data, response, error in
				
				guard error == nil else
				{
					next(.fail(with: error ?? Failure.unknown)) // interrupt the chain
					return
				}

				guard let httpStatus = response as? HTTPURLResponse, (200 ... 299).contains(httpStatus.statusCode) else
				{
					let error = Failure.httpError(
						code: (response as? HTTPURLResponse)?.statusCode, message: String(describing: response))

					next(.fail(with: error)) // interrupt the chain
					return
				}

				_ = data // unused
				
				next(.continue) // continue the chain
			}

			task.resume()
		}

		let task2: AsyncTaskGroup.Task = { status, next in
			
			guard status.isCancelled == false else
			{
				next(.continue) // give other chain participants a chance to cancel gracefully
				return
			}
			
			let endpointURL = Config.endpointURL(forObjectId: 2)

			let request = URLRequest(url: URL(string: endpointURL)!)
			let task = URLSession.shared.dataTask(with: request) { data, response, error in
				
				guard error == nil else
				{
					next(.fail(with: error ?? Failure.unknown)) // interrupt the chain
					return
				}

				guard let httpStatus = response as? HTTPURLResponse, (200 ... 299).contains(httpStatus.statusCode) else
				{
					let error = Failure.httpError(
						code: (response as? HTTPURLResponse)?.statusCode, message: String(describing: response))

					next(.fail(with: error)) // interrupt the chain
					return
				}

				_ = data // unused
				
				next(.continue) // continue the chain
			}

			task.resume()
		}

		// FYI: asynchronous .execute() runs each block on a global dispatch queue, thus UI will be pumped

		let tasks = AsyncTaskGroup(onError: failureHandler,

			task1,
			task2,
			
			{ status, next in
			
				// always attempt to signal the semaphore
				_ = status.isCancelled
			
				// the async task group is complete, allow the simulacrum to be destroyed
				semaphore.signal()
				
				next(.continue)
			}
		)
		
		//
		
		if let wip = wip
		{
			// if a task group is already executing, cancel it first
			wip.cancelAllTasks()
		}

		wip = tasks

		tasks.execute()
	}
	
	// MARK: - private
	
	private var wip: AsyncTaskGroup?
}

let simul = ViewControllerSimulacrum()
simul.executeAsyncTasks()

// must wait for the task group execution thread to complete, otherwise the Xcode
// playground execution thread will exit and the simulacrum will be destroyed
semaphore.wait()
