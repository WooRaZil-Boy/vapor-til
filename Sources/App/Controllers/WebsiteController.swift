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
        router.get("categories", use: allCategoriesHandler)
        //모든 category 보기 페이지 GET request. 경로는 http://localhost:8080/categories 가 된다.
        router.get("categories", Category.parameter, use: categoryHandler)
        //category 보기 페이지 GET request. 경로는 http://localhost:8080/categories/<ID> 가 된다.
        router.get("acronyms", "create", use: createAcronymHandler)
        //acronym 생성 페이지 GET request. 경로는 http://localhost:8080/acronyms/create 가 된다.
        router.post(Acronym.self, at: "acronyms", "create", use: createAcronymPostHandler)
        //acronym 생성 페이지 POST request. 경로는 http://localhost:8080/acronyms/create 가 된다.
        router.get("acronyms", Acronym.parameter, "edit", use: editAcronymHandler)
        //acronym 수정 페이지 GET request. 경로는 http://localhost:8080/acronyms/<ID>/edit 가 된다.
        router.post("acronyms", Acronym.parameter, "edit", use: editAcronymPostHandler)
        //acronym 수정 페이지 POST request. 경로는 http://localhost:8080/acronyms/<ID>/edit 가 된다.
        router.post("acronyms", Acronym.parameter, "delete", use: deleteAcronymHandler)
        //acronym 삭제 페이지 POST request. 경로는 http://localhost:8080/acronyms/<ID>/delete 가 된다.
        //브라우저는 페이지 request를 요청하는 GET과 form을 사용해 데이터를 보내는 POST request만 보낼 수 있다.
        //cf. JavaScript로 DELETE request를 보낼 수도 있다.
        //따라서 POST request를 삭제 경로에 보내야 한다.
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
                //flatMap으로 result를 unwrapping한다.
                return acronym.user //acronym의 user를 가져오고
                    .get(on: req)
                    .flatMap(to: View.self) { user in //flatMap으로 result를 unwrapping한다.
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
                //flatMap으로 result를 unwrapping한다.
                return try user.acronyms //user의 acronyms를 가져오고
                    .query(on: req)
                    .all()
                    .flatMap(to: View.self) { acronyms in //flatMap으로 result를 unwrapping한다.
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
                //flatMap으로 result를 unwrapping한다.
                let context = AllUsersContext(title: "All Users", users: users)
                //세부 정보가 있는 AllUsersContext를 생성
                
                return try req.view().render("allUsers", context)
                //allUsers.leaf 템플릿을 사용해서 페이지를 렌더링한다.
            }
    }
    
    func allCategoriesHandler(_ req: Request) throws -> Future<View> { //Future<View> 반환
        //All Category page
        let categories = Category.query(on: req).all() //all() 이후 flatMap할 필요 없다.
        let context = AllCategoriesContext(categories: categories)
        //이전과 달리 AllCategoriesContext에서는 Leaf가 Future를 처리할 수 있으므로 context에 쿼리 결과를 바로 포함한다.
        //AllCategoriesContext의 categories는 Future<[Category]> 타입이다. 따라서 flatMap으로 unwrapping할 필요 없다.
        
        return try req.view().render("allCategories", context)
        //allCategories.leaf 템플릿을 사용해서 페이지를 렌더링한다.
    }
    
    func categoryHandler(_ req: Request) throws -> Future<View> { //Future<View> 반환
        //Category page
        return try req.parameters.next(Category.self)
            //매개 변수에서 Category를 추출하고
            .flatMap(to: View.self) { category in
                //flatMap으로 result를 unwrapping한다.
                let acronyms = try category.acronyms.query(on: req).all() //all() 이후 flatMap할 필요 없다.
                let context = CategoryContext(title: category.name, category: category, acronyms: acronyms)
                //이전과 달리 CategoryContext에서는 Leaf가 Future를 처리할 수 있으므로 context에 쿼리 결과를 바로 포함한다.
                //CategoryContext의 acronyms는 Future<[Acronym]> 타입이다. 따라서 flatMap으로 unwrapping할 필요 없다.
                
                return try req.view().render("category", context)
                //category.leaf 템플릿을 사용해서 페이지를 렌더링한다.
            }
    }
    
    func createAcronymHandler(_ req: Request) throws -> Future<View> { //Future<View> 반환
        //Creating Acronym page for GET
        let context = CreateAcronymContext(users: User.query(on: req).all()) //all() 이후 flatMap할 필요 없다.
        //모든 User를 가져온다.
        //CreateAcronymContext에서는 Leaf가 Future를 처리할 수 있으므로 context에 쿼리 결과를 바로 포함한다.
        //CreateAcronymContext의 acronyms는 Future<[User]> 타입이다. 따라서 flatMap으로 unwrapping할 필요 없다.
        
        return try req.view().render("createAcronym", context)
        //createAcronym.leaf 템플릿을 사용해서 페이지를 렌더링한다.
    }
    
    func createAcronymPostHandler(_ req: Request, acronym: Acronym) throws -> Future<Response> { //Future<Response> 반환
        //Creating Acronym page for POST //Vapor는 form 데이터를 Acronym으로 자동 디코딩한다.
        return acronym.save(on: req).map(to: Response.self) { acronym in
            //매개 변수의 Acronym을 DB에 저장. //unwrapping한다.
            //map()과 flatMap()은 모두 Future를 다른 유형의 Future로 매핑한다.
            //단, 클로저의 매개 변수(in 앞의 값)가 map()에서는 실제 값이이고, flatMap()에서는 Futrue이다.
            guard let id = acronym.id else { //id 유효성 확인
                throw Abort(.internalServerError)
                //500 Internal Server Error
            }
            
            return req.redirect(to: "/acronyms/\(id)")
            //새로 생성된 acronym 상세 정보 페이지로 redicrection 한다.
        }
    }
    
    //웹 응용 프로그램에서 Acronym을 생성하려면 두 개의 경로를 구현해야 한다.
    //Acronym 생성 시 정보를 입력하는 GET request와, 입력된 정보를 DB로 보내 생성하고 승인하는 POST request가 필요하다.
    //Acronym 생성 페이지에는 모든 User의 목록이 있어야 생성시, 소유 User 목록을 선택하게 할 수 있다.
    
    func editAcronymHandler(_ req: Request) throws -> Future<View> { //Future<View> 반환
        //Editing Acronym page for GET
        return try req.parameters.next(Acronym.self)
            .flatMap(to: View.self) { acronym in
                let context = EditAcronymContext(acronym: acronym, users: User.query(on: req).all())
                //Acronym을 편집하여 모든 User 를 전달하는 Context
                //모든 User를 가져온다.
                
                return try req.view().render("createAcronym", context)
                //createAcronym.leaf 템플릿을 사용해서 페이지를 렌더링한다.
            }
    }
    
    func editAcronymPostHandler(_ req: Request) throws -> Future<Response> { //Future<Response> 반환
        //Editing Acronym page for POST
        return try flatMap(to: Response.self, req.parameters.next(Acronym.self), req.content.decode(Acronym.self)) { acronym, data in
            //파라미터로 to: Response(최종 반환형), id로 요청해서 가져온 객체(수정할 객체), 디코딩 객체(form 에서 입력한 정보)
            
            acronym.short = data.short
            acronym.long = data.long
            acronym.userID = data.userID
            //Acronym 업데이트
            
            return acronym.save(on: req) //DB에 저장
                .map(to: Response.self) { savedAcronym in
                    //반환된 Futuref를 unwrapping
                    guard let id = savedAcronym.id else { //id가 유효한지 확인
                        throw Abort(.internalServerError)
                        //500 Internal Server
                    }
                    
                    return req.redirect(to: "/acronyms/\(id)")
                    //업데이트가 된 acronym 상세 정보 페이지로 redicrection 한다.
                }
            }
    }
    
    //웹 응용 프로그램에서 Acronym을 수정하려면 두 개의 경로를 구현해야 한다.
    //Acronym 수정 시 정보를 입력하는 GET request와, 입력된 정보를 DB로 보내 생성하고 승인하는 POST request가 필요하다.
    //Acronym 생수정 페이지에는 모든 User의 목록이 있어야 생성시, 소유 User 목록을 선택하게 할 수 있다.
    
    func deleteAcronymHandler(_ req: Request) throws -> Future<Response> { //Future<Response> 반환
        //Deleting Acronym page
        //삭제는 위의 Creat, Update와 달리 단일 경로만 있으면 된다.
        //그러나, 웹 브라우저에서는 DELETE request를 보내는 간단한 방법이 없다.
        //브라우저는 페이지 request를 요청하는 GET과 form을 사용해 데이터를 보내는 POST request만 보낼 수 있다.
        //cf. JavaScript로 DELETE request를 보낼 수도 있다.
        //따라서 POST request를 삭제 경로에 보내야 한다.
        //이전 AcronymsController에서는 따로 HTML문서 없이 API JSON만 보내므로 상관 없었다.
        return try req.parameters.next(Acronym.self).delete(on: req)
            //Request의 매개변수에서 Acronym을 추출하고, delete(on :) 호출해 삭제
            .transform(to: req.redirect(to: "/"))
            //삭제 후 root 페이지로 redicrection 한다.
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

struct AllCategoriesContext: Encodable {
    //모든 Category 정보를 표시하는 페이지의 Encodable 유형
    let title = "All Categories"
    let categories: Future<[Category]>
    //Leaf에서도 Future를 처리할 수 있다.
    //Handler에서 wrapping된 Future에 접근할 필요 없을 경우 이렇게 선언하면, 코드를 간단하게 정리할 수 있다.
}

struct CategoryContext: Encodable {
    //Category 정보를 표시하는 페이지의 Encodable 유형
    let title: String
    let category: Category //title을 설정하려면 카테고리의 이름이 필요하므로 Future<Category>가 아니다.
    //따라서 handler에서 해당 속성의 Future를 unwrapping해야 한다.
    let acronyms: Future<[Acronym]>
    //Leaf에서도 Future를 처리할 수 있다.
    //Handler에서 wrapping된 Future에 접근할 필요 없을 경우 이렇게 선언하면, 코드를 간단하게 정리할 수 있다.
}

struct CreateAcronymContext: Encodable {
    //Acronym 생성 페이지의 Encodable 유형
    let title = "Create An Acronym"
    let users: Future<[User]>
    //Leaf에서도 Future를 처리할 수 있다.
    //Handler에서 wrapping된 Future에 접근할 필요 없을 경우 이렇게 선언하면, 코드를 간단하게 정리할 수 있다.
}

struct EditAcronymContext: Encodable {
    //Acronym 수정 페이지의 Encodable 유형
    let title = "Edit Acronym"
    let acronym: Acronym
    let users: Future<[User]>
    //Leaf에서도 Future를 처리할 수 있다.
    //Handler에서 wrapping된 Future에 접근할 필요 없을 경우 이렇게 선언하면, 코드를 간단하게 정리할 수 있다.
    let editing = true //수정 인지 생성인지 템플릿에 알려주는 flag
}

//Vapor와 마찬가지로 Leaf는 Codable을 사용하여 데이터를 처리한다.




//Leaf
//Leaf는 Vapor의 템플릿 언어이다. 템플릿 언어를 사용하면 front에 대한 지식이 많지 않아도 쉽게 HTML을 생성하고 정보를 보낼 수 있다.
//ex. 이 앱에서 모든 Acronym 정보를 알 지 않아도 템플릿을 사용하면, 쉽게 처리할 수 있다.
//템플릿 언어를 사용하면 웹 페이지의 중복을 줄일 수 있다. Acronym에 대한 여러 페이지 대신 단일 템플릿을 작성하고 특정 Acronym에 관련된 정보를 설정한다.
//Acronym를 표시하는 방식을 변경하려는 경우, 한 곳에서만 코드를 변경하면 모든 페이지에 새 형식이 적용된다.
//템플릿 언어를 사용하면, 템플릿을 다른 템플릿에 포함시킬 수도 있다.

