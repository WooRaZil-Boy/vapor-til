import Vapor

struct CategoriesController: RouteCollection {
    //RouteCollection를 구현해, route를 관리하는 Controller를 구현할 수 있다.
    
    func boot(router: Router) throws {
        //RouteCollection에서는 반드시 이 메서드를 구현해야 한다.
        let categoriesRoute = router.grouped("api", "categories")
        //반복되는 경로에 대해 새 초기 경로 그룹을 생성한다(/api/categories).
        
        categoriesRoute.post(Category.self, use: createHandler)
        //생성은 POST 요청을 사용한다. 경로는 http://localhost:8080/api/categories 가 된다.
        //POST helper (save(on:))메서드를 사용해서, request body에서 User 객체로 디코딩한다.
        categoriesRoute.get(use: getAllHandler)
        //GET 요청을 처리하는 경로. 여기서는 http://localhost:8080/api/users 가 된다.
        categoriesRoute.get(Category.parameter, use: getHandler)
        //GET 요청을 처리하는 경로. 여기서는 http://localhost:8080/api/users/<ID> 가 된다.
        categoriesRoute.get(Category.parameter, "acronyms", use: getAcronymsHandler)
        //형제 관계 검색은 GET 요청. 경로는 http://localhost:8080/api/categories/<ID>/acronyms 가 된다.
    }
    
    //Create
    func createHandler(_ req: Request, category: Category) throws -> Future<Category> {
        //이 메서드는 매개변수로 Category를 가져온다. Category는 이미 decode 되었기 때문에 따로 decode()할 필요 없다.
        return category.save(on: req) //디코드된 Category를 저장한다. //Fluent의 모델 저장 메서드
    }
    
    //Retrieve
    func getAllHandler(_ req: Request) throws -> Future<[Category]> {
        return Category.query(on: req).all() //모든 Category 반환
    }
    
    func getHandler(_ req: Request) throws -> Future<Category> {
        return try req.parameters.next(Category.self)
        //request의 매개 변수로 지정된 User를 반환한다.
    }
    
    
    
    
    //Querying the relationship
    func getAcronymsHandler(_ req: Request) throws -> Future<[Acronym]> {
        return try req.parameters.next(Category.self) //파라미터를 가져온다.
            .flatMap(to: [Acronym].self) { category in //flatMap으로 request의 파라미터에서 Category를 추출하고 unwrapping한다.
                //to: 는 flatMap 이후 최종 반환형
                try category.acronyms.query(on: req).all()
                //computed property에서 Acronym를 가져오고 Fluent 쿼리를 사용해서 모든 Acronym를 반환한다.
        }
    }
}
