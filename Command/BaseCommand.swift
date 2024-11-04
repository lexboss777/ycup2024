class BaseCommand {
    let id: UInt32
    weak var canvas: CanvasView?

    init(id: UInt32, canvas: CanvasView?) {
        self.id = id
        self.canvas = canvas
    }

    func execute() -> Bool {
        fatalError("Must override")
    }

    func cancel() -> Bool {
        fatalError("Must override")
    }
}
