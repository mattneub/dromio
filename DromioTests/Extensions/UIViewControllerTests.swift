@testable import Dromio
import UIKit
import Testing
import WaitWhile

struct UIViewControllerTests {
    @Test("ultimatePresented: works as expected")
    func ultimatePresented() async {
        let root = UIViewController()
        makeWindow(viewController: root)
        #expect(root.ultimatePresented == root)

        let presented1 = UIViewController()
        root.present(presented1, animated: false)
        await #while(root.presentedViewController == nil)
        #expect(root.ultimatePresented === presented1)

        let presented2 = UIViewController()
        presented1.present(presented2, animated: false)
        await #while(presented1.presentedViewController == nil)
        #expect(root.ultimatePresented === presented2)

        #expect(presented1.ultimatePresented === presented2)
        #expect(presented2.ultimatePresented == presented2)
    }
}
