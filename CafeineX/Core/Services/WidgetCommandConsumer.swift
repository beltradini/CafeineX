import Foundation

@MainActor
enum WidgetCommandConsumer {
    /// A crash between save and acknowledge replays the same operation UUID.
    @discardableResult
    static func consume(
        queue: WidgetCommandQueue,
        save: (PendingWidgetDrinkCommand) throws -> Void
    ) throws -> Int {
        var count = 0
        for command in try queue.pending() {
            try save(command)
            try queue.acknowledge(id: command.id)
            count += 1
        }
        return count
    }
}
