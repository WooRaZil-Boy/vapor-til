import Vapor
import Leaf

struct WebsiteController: RouteCollection {
    //Website 관리하는 객체. API와 달리 보여지는 뷰가 있어여 한다.
    func boot(router: Router) throws {
        //RouteCollection에서는 반드시 이 메서드를 구현해야 한다.
        router.get(use: indexHandler)
        //router의 경로로 GET request. 등록된 메서드(indexHandler)를 처리한다. 경로는 http://localhost:8080/ 가 된다.
        router.get("acronyms", Acronym.parameter, use: acronymHandler)
        //acronyms 상세보기 페이지 GET request. 경로는 http://localhost:8080/acronyms/<ID> 가 된다.
        router.get("users", User.parameter, use: userHandler)
        //user 보기 페이지 GET request. 경로는 http://localhost:8080/users/<ID> 가 된다.
        router.get("users", use: allUsersHandler)
        //모든 user 보기 페이지 GET request. 경로는 http://localhost:8080/users 가 된다.
    }
    
    func indexHandler(_ req: Request) throws -> Future<View> { //Future<View> 반환
        //Index page
        return Acronym.query(on: req)
            .all() //DB의 모든 Acronym을 가져온다.
            .flatMap(to: View.self) { acronyms in
                let acronymsData = acronyms.isEmpty ? nil : acronyms //비어 있는 경우 : 1개라도 있는 경우
                let context = IndexContext(title: "Homepage", acronyms: acronymsData)
                //title과 Acronym 배열을 포함하는 IndexContext를 생성한다.
                
                return try req.view().render("index", context) //IndexContext를 템플릿에 전달한다.
                //템플릿을 렌더링하고, 결과를 반환한다.
                //렌더러를 얻기 위해 일반적으로 req.view()를 사용하면 다른 템플릿 엔진으로 쉽게 전환할 수 있다.
                //req.view()에 Vapor에 ViewRenderer를 준수하는 유형을 사용해야 한다.
                //Leaf가 빌드된 모듈인 TemplateKit은 PlaintextRenderer를 제공하고, Leaf는 LeafRenderer를 제공한다.
                
                //기본적으로 Leaf 템플릿은 Resources/Views 에 위치해야 한다.
                //Leaf는 Resources/Views 디렉토리의 index.leaf라는 템플릿에서 페이지를 생성한다(render 파라미터로 확장자는 생략한다).
            }
    }
    
    func acronymHandler(_ req: Request) throws -> Future<View> { //Future<View> 반환
        //Acronym detail page
        return try req.parameters.next(Acronym.self)
            //매개 변수에서 Acronym를 추출하고
            .flatMap(to: View.self) { acronym in
                //flatMap으로 result를 wrapping한다.
                return acronym.user //acronym의 user를 가져오고
                    .get(on: req)
                    .flatMap(to: View.self) { user in //flatMap으로 result를 wrapping한다.
                        let context = AcronymContext(title: acronym.short, acronym: acronym, user: user)
                        //세부 정보가 있는 AcronymContext를 생성
                        return try req.view().render("acronym", context)
                        //acronym.leaf 템플릿을 사용해서 페이지를 렌더링한다.
                    }
            }
    }
    
    func userHandler(_ req: Request) throws -> Future<View> { //Future<View> 반환
        //User page
        return try req.parameters.next(User.self)
            //매개 변수에서 User를 추출하고
            .flatMap(to: View.self) { user in
                //flatMap으로 result를 wrapping한다.
                return try user.acronyms //user의 acronyms를 가져오고
                    .query(on: req)
                    .all()
                    .flatMap(to: View.self) { acronyms in //flatMap으로 result를 wrapping한다.
                        let context = UserContext(title: user.name, user: user, acronyms: acronyms)
                        //세부 정보가 있는 UserContext를 생성
                        return try req.view().render("user", context)
                        //user.leaf 템플릿을 사용해서 페이지를 렌더링한다.
                    }
            }
    }
    
    func allUsersHandler(_ req: Request) throws -> Future<View> { //Future<View> 반환
        //All User page
        return User.query(on: req)
            .all()
            .flatMap(to: View.self) { users in
                //flatMap으로 result를 wrapping한다.
                let context = AllUsersContext(title: "All Users", users: users)
                //세부 정보가 있는 AllUsersContext를 생성
                return try req.view().render("allUsers", context)
                //allUsers.leaf 템플릿을 사용해서 페이지를 렌더링한다.
            }
    }
}

struct IndexContext: Encodable {
    //메인 페이지에서 보여줄 타이틀과, 각 acronyms를 가지고 있는 Encodable 유형
    let title: String
    let acronyms: [Acronym]? //Acronym 배열
    //Acronym이 DB에 하나도 없는 경우가 있으므로 optional이다.
    
    //leaf 파일에서 #()는 Leaf 함수를 나타낸다.
    //이 함수의 파라미터를 사용해 데이터를 가져올 수 있다.
    //데이터는 오직 Leaf에서만 처리되기 때문에, Encodable만 구현하면됩니다.
    //즉, IndexContext는 MVVM 디자인 패턴의 View Model과 비슷한 view에 데이터를 전달해 주는 역할이다.
}

struct AcronymContext: Encodable {
    //하나의 acronym의 세부 정보를 표시하는 페이지의 Encodable 유형
    let title: String
    let acronym: Acronym
    let user: User
}

struct UserContext: Encodable {
    //User 정보를 표시하는 페이지의 Encodable 유형
    let title: String
    let user: User
    let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
    //모든 User 정보를 표시하는 페이지의 Encodable 유형
    let title: String
    let users: [User]
}

//Vapor와 마찬가지로 Leaf는 Codable을 사용하여 데이터를 처리한다.




//Leaf
//Leaf는 Vapor의 템플릿 언어이다. 템플릿 언어를 사용하면 front에 대한 지식이 많지 않아도 쉽게 HTML을 생성하고 정보를 보낼 수 있다.
//ex. 이 앱에서 모든 Acronym 정보를 알 지 않아도 템플릿을 사용하면, 쉽게 처리할 수 있다.
//템플릿 언어를 사용하면 웹 페이지의 중복을 줄일 수 있다. Acronym에 대한 여러 페이지 대신 단일 템플릿을 작성하고 특정 Acronym에 관련된 정보를 설정한다.
//Acronym를 표시하는 방식을 변경하려는 경우, 한 곳에서만 코드를 변경하면 모든 페이지에 새 형식이 적용된다.
//템플릿 언어를 사용하면, 템플릿을 다른 템플릿에 포함시킬 수도 있다.

