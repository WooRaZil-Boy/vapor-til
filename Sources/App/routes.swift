import Vapor

/// Register your application's routes here.
public func routes(_ router: Router) throws {
    // Basic "Hello, world!" example
    router.get("hello") { req in
        //GET 요청 처리하는 경로. http://localhost:8080/hello
        return "Hello, world!"
    }
    
    router.post("api", "acronyms") { req -> Future<Acronym> in //Future<Acronym> 타입을 반환한다.
        //POST 요청을 처리하는 경로. 여기서는 http://localhost:8080/api/acronyms 이 된다.
        return try req.content.decode(Acronym.self)
            //request JSON을 Codeable을 사용해, Acronym 모델로 디코딩한다.
            .flatMap(to: Acronym.self) { acronym in
                //디코더가 Future<Acronym>을 반환하므로, flatMap(to:)를 사용한다.
                return acronym.save(on: req) //Fluent의 모델 저장 메서드
                //Fluent (Acronym)을 사용하여 모델을 저장한다.
                //Fluent는 저장되면서 모델을 반환한다(여기서는 Future<Acronym>).
                
                //Fluent와 Vapor의 Codable을 사용하면 간단히 작업할 수 있다.
                //Acronym는 Content를 구현했으므로, JSON과 Model간에 쉽게 변환할 수 있다.
                //Vapor는 손쉽게 response에서 Model을 JSON으로 반환한다.
        }
    }
    
    //    // Example of configuring a controller
    //    let todoController = TodoController()
    //    router.get("todos", use: todoController.index)
    //    router.post("todos", use: todoController.create)
    //    router.delete("todos", Todo.parameter, use: todoController.delete)
    //Default 컨트롤러(예제)
}



//Deploying to Vapor Cloud
//Vapor Cloud는 Vapor 응용 프로그램을 호스팅하기 위해 Vapor에서 제작한 PaaS(Platform as a Service)이다.
//서버 구성 및 배포 관리를 단순화하여 코드 작성에 집중할 수 있도록 해 준다.
//Vapor Cloud를 사용하는 응용 프로그램 구성은 cloud.yml에서 작성한다.

//Vapor Toolbox를 사용하면 Vapor Cloud 명령과 상호 작용할 수 있다.
//터미널에서 해당 폴더에서 vapor cloud login 로 로그인 후,
//vapor cloud deploy 로 응용 프로그램을 배포한다.

//Adding a repository
//GitHub repository에 추가해야 Vapor Cloud에 배포할 수 있다.
//생성 후, github ssh를 입력해 주면된다.

//Creating a project and application
//repository에 추가 후 자동으로 커밋이 되면, 애플리케이션을 생성할 지 물어본다.
//프로젝트를 소유할 조직을 선택하고, 프로젝트의 이름을 지정해 주면 된다.
//프로젝트를 Run한 이후에 진행해야 해야 Error가 나지 않는다.
//Slug는 URL의 일부를 구성하는 애플리케이션 고유 식별자이다(중복되어선 안 된다.).

//Setting up hosting
//호스팅 서비스를 추가하면 클라우드에 코드를 배포할 수 있다.
//위에서 선택한 Github URL로 설정할 수 있다.

//Setting up environments
//이후 environment 설정을 묻는다. environment에 대한 이름을 설정해 주면 된다.
//환경 설정은 기본적으로 다른 git 브런치에 적용할 수 있다. master를 지정해 줘도 된다.

//Final configuration
//환경을 구성했으면 해당 환경의 복제본 크기를 선택해야 한다.
//복제본 크기는 응용 프로그램을 호스팅하는 하드웨어로 용량이 클수록 처리 능력이 좋지만, 유료이다.
//다음으로 Vapor Cloud가 DB를 구성할 것인지 묻는다. 현재 SQLite를 사용하고 있으므로 추가적으로 필요하진 않다.
//마지막으로 build type을 설정한다.
//• Incremental : 기존 빌드 아티팩트를 사용해 코드를 컴파일해 빌드시간을 단축한다.
//• Update : 매니페시트에서 허용하는 모든 종속성을 업데이트 한다.
//• Clean : 모든 종속성 밒 기존 빌드 아티팩트를 정리한다.
//초기 빌드는 Clean을 사용하는 것이 좋다.

//Build, deploy and test
//build를 하면, 애플리케이션을 컴파일하고, Docker 이미지를 생성해 Vapor Cloud 컨테이너 저장소에 푸시한다.
//빌드가 끝나면, 앱에 대한 URL과 성공 메시지를 출력한다.




//Docker를 사용해 DB를 호스팅할 수 있다. Docker는 가상 시스템의 오버 헤드없이 시스템에서 독립적인 이미지를 실행할 수 있는 컨테이너 기술이다.
//서로 다른 DB를 생성할 수 있으며 종속성 또는 DB를 서로 간섭하지 않는다.

//Choosing a database
//Vapor의 공식적인 Swift-native driver는 SQLite, MySQL, PostgreSQL이 있다.
//Vapor는 관계형 DB만 지원한다(NoSQL 지원하지 않는다).
//• SQLite : 파일 기반 간단한 관계형 DB. 응용 프로그램에 내장되도록 설계. iOS 같은 단일 프로세스 프로그램에 유용
//  파일 잠금을 사용하여 DB 무결성을 유지하므로 쓰기가 많은 응용프로그램에는 적합하지 않다.
//• MySQL : LAMP web application stack (Linux, Apache, MySQL, PHP)에서 널리 사용되는 관계형 DB
//• PostgreSQL : 확장성 및 표준성에 중점을 둔 오픈소스 DB로 기업용으로 설계되었다.
//  좌표같은 기하학적 기본요소를 지원한다. Fluent는 Dictionary 같은 중첩된 유형을 Postgres에 직접저장하고, 프리미티브를 지원한다.




//Configuring Vapor
//Vapor가 DB를 사용하도록 구성하면, 다음 단계를 수행한다.
//• 해당 DB의 Fluent Provider를 응용 프로그램의 서비스에 추가한다.
//• 데이터베이스를 구성한다.
//• 마이그레이션을 구성한다.
//서비스는 컨테이너에서 생성하고 액세스하는 방법을 말한다. Vapor에서 상호작용하는 가장 일반적인 컨테이너는
//애플리케이션 자체, 요청 및 응답이다. 이 응용프로그램을 사용해 부팅하는데 필요한 서비스를 만들어야 한다.
//해당 요청을 처리하는 동안 암호를 해시하려면 요청 및 응답 컨테이너를 사용해서 BCryptHasher 같은 서비스를 만들어야 한다.






