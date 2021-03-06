//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import UIKit
import MarkupKit

class ScrollViewController: UIViewController {
    @IBOutlet var label1: UILabel!
    @IBOutlet var label2: UILabel!

    override func loadView() {
        view = LMViewBuilder.viewWithName("ScrollView", owner: self, root: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let textPath = NSBundle.mainBundle().pathForResource("sample", ofType: "txt")
        let text = NSString(contentsOfFile: textPath!, encoding: NSASCIIStringEncoding, error: nil)

        label1.text = text as String?
        label2.text = text as String?
    }
}
