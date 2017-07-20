//MARK: copy the code between the comment marks below to a code snippet in Xcode to make things easier when making JakeFakes

/*


class Fake<#CLASS_NAME#>: <#CLASS_NAME#>, JakeFake {
    enum Function: JakeFakeFunction {
        //create cases here that correspond to methods you will override below

        public static func ==(lhs: Function, rhs: Function) -> Bool {
            switch (lhs, rhs) {
            default:
                return false
            }
        }

        public var hashValue: Int {
            switch self {
            default:
                return 0
            }
        }
    }

    let faker: JakeFaker<Function> = JakeFaker()

    //MARK: - overrides

    //override methods here

}


*?
