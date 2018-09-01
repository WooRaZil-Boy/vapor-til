import FluentPostgreSQL
import Vapor

struct AddTwitterURLToUser: Migration {
    //새로운 필드를 모델에 추가하는 마이그레이션. User의 prepare(on:) 참고
    typealias Database = PostgreSQLDatabase //Migration에서 사용할 DB 유형 정의
    
    static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
        //Migration 시 DB 변경 사항
        return Database.update(User.self, on: connection) { builder in
            //User 모델은 이미 DB에 있으므로 update 한다.
            builder.field(for: \.twitterURL)
            //업데이트는 클로저 내에서 이뤄진다. twitterURL 필드를 추가한다.
        }
    }
    
    static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
        //prepare(on:)에서 했던 일을 취소해야 할 때
        return Database.update(User.self, on: connection) { builder in
            //기존 User 모델을 수정하기 때문에 update 한다.
            builder.deleteField(for: \.twitterURL)
            //업데이트는 클로저 내에서 이뤄진다. twitterURL 필드를 제거한다.
        }
    }
}




//Modifying tables
//기존 DB가 서비스 중일 때에는 단순히 테이블에서 속성을 추가하거나 제거할 수 없다.
//대신 Vapor의 Migration 프로토콜을 사용하여 수정 할 수 있다.
//이는 예상대로 진행되지 않았을 때 revert 하는 옵션을 포함하고 있다.
//중요한 데이터가 많은 경우 DB를 수정하기 전에 백업을 하는 것이 좋다.
//코드를 깨끗하게 유지하고 변경 사항을 순서대로 보려면 모든 마이그레이션이 포함된 디렉토리를 만들어야 한다.
//파일 이름의 경우 일관되고 유용한 이름을 사용한다. ex. YY-MM-DD-FriendlyName.swift

//Writing migrations
//마이그레이션은 일반적으로 기존 모델을 업데이트 하는 구조체로 작성된다. 이 구조체는 Migration을 구현해야 한다.
//마이그레이션을 수행하려면 다음 세 가지를 구현해야 한다.

//typealias Database: Fluent.Database
//static func prepare(on connection: Database.Connection) -> Future<Void>
//static func revert(on connection: Database.Connection) -> Future<Void>

// • Typealias Database
//마이그레이션을 실행할 수 있는 DB 유형을 지정해야 한다. 마이그레이션을 수행하려면 MigrationLog 모델을 쿼리할 수 있어야 하므로
//DB 연결이 올바르게 작동해야 한다. MigrationsLog에 액세스 할 수 없는 경우 마이그레이션이 실패하고 최악의 경우 응용 프로그램이 중단된다.

// • Prepare method
//prepare(on:) 에는 마이그레이션에 대한 DB 변경 사항이 들어 있다. 대개 새 테이블을 생성하거나 새 속성을 추가해 기존 테이블을 수정하는 것이다.

//static func prepare(on connection: PostgreSQLConnection) -> Future<Void> {
//    return Database.create( //DB에 새 Model 추가 //기존 모델에 속성을 추가하는 경우는 update(_:on:closure:)를 사용
//        NewTestUser.self,
//        on: connection
//        ) { builder in //실제 수정을 하는 클로저
//            builder.field(for: \.id, isIdentifier: true)
//            //field(for:)를 호출해 모델에 추가할 각 필드를 수정할 수 있다.
//            //일반적으로 Fluent가 필드를 유추할 수 있으므로 필드 유형을 포함할 필요는 없다.
//    }
//}

// • Revert method
//revert(on:)는 prepare(on:)의 역이다. prepare(on:)에서 했던 일을 취소한다.
//prepare(on:)에 create(_:on:closure:)를 사용해 생성했다면 revert(on:)에서는 delete(_:on:)를 사용해 테이블을 삭제한다.
//update(_:on:closure:)를 사용하여 필드를 추가했다면, revert(on:)에서는 deleteField(for:)를 사용해 필드를 제거한다.

//static func revert(on connection: PostgreSQLConnection) -> Future<Void> {
//    return Database.delete(NewTestUser.self, on: connection)
//}

//이는 --revert 옵션으로 앱을 부팅할 때 실행할 수 있다.

//마이그레이션이 제대로 됐는지 테이블을 확인하려면 터미널에서 p.378

//docker exec -it postgres psql -U vapor
//\d "User"
//\q
//를 입력해 보면 된다.




//Deploy to Vapor Cloud
//이전에는 모델을 변경할 때 마다 전체 DB를 삭제해야 했지만, 마이그레이션이 제대로 완료된 경우에는 그럴 필요 없이 바로 Deploy 할 수 있다.
//https://docs.vapor.codes/3.0/fluent/migrations/














//캐시는 느린 프로세스를 빠르게 하는 방법이며, 웹 응응 프로그램을 빌드하는 동안 발생할 수 있는 느린 프로세스는 다음과 같다.
// • 대형 DB 쿼리
// • 외부 서비스 request(다른 API)
// • 복잡한 계산(ex. 큰 문서의 파싱)
//이런 느린 프로세스의 결과를 캐싱하면 앱의 속도가 빨라지고, response 속도가 향상된다.

//Cache storage
//DatabaseKit의 일부로 Vapor는 KeyedCache 프로토콜을 사용한다.
//이 프로토콜은 캐시 저장 방법에 대한 공통 인터페이스를 생성한다. 구조는 다음과 같다.

//public protocol KeyedCache {
//    func get<D>(_ key: String, as decodable: D.Type) -> Future<D?> where D: Decodable
//    //지정된 키의 캐시에서 저장된 데이터에 접근한다. 해당 키에 대한 데이터가 없으면 nil을 반환한다.
//    func set<E>(_ key: String, to encodable: E) -> Future<Void> where E: Encodable
//    //지정된 키의 캐시에 데이터를 저장한다. 이전 값이 있다면 덮어쓴다.
//    func remove(_ key: String) -> Future<Void>
//    //지정된 키의 캐시에서 데이터가 존재하는 경우 제거한다.
//}

//각 메서드는 캐시와 상호 작용이 비동기로 발생할 수 있으므로 Future를 반환한다.

//In-memory caches
//Vapor에서 MemoryKeyedCache 와 DictionaryKeyedCache 의 두 개의 메모리 키반 캐시가 제공된다.
//이러한 캐시는 프로그램의 실행 메모리에 데이터를 저장한다. 따라서 외부 종속성이 없기 때문에 두 캐시 모두 개발 및 테스트에 적합하다.
//그러나 응용 프로그램이 다시 시작될 때 저장한 캐시가 지워지고, 응용 프로그램의 여러 인스턴스 간에 공유할 수 없기 때문에 모든 용도에 완벽하지 않다.
//MemoryKeyedCache 와 DictionaryKeyedCache 의 차이점은 그리 크지 않다.

// • Memory cache
//MemoryKeyedCache의 내용은 모든 응용 프로그램의 이벤트 루프에서 공유된다.
//즉, 캐시에 항목이 저장되면 나중에 모든 request에 할당된 이벤트 루프에 관계없이 동일한 항목이 표시된다.
//하지만, 이 캐시는 thread safe 하지 않으므로, 동기화 된 액세스가 필요하다.
//따라서 MemoryKeyedCache는 릴리즈된 프로덕션 시스템에서 사용하기는 적합하지 않다.

// • Dictionary cache
//DictionaryKeyedCache의 내용으 각 이벤트 루프에 대해 local이다.
//즉, 다른 이벤트 루프에 할당 된 후속 request에 캐시된 다른 데이터가 표시될 수 있다.
//performance-based 같은 성능 기반 캐싱에 적합하지만, 세션 저장과 같은 용도로 DictionaryKeyedCache를 사용하는 경우 문제가 생길 수 있다.
//DictionaryKeyedCache 는 이벤트 루프 간에 메모리를 공유하지 않기 때문에 릴리즈된 프로덕션 시스템에서 사용하기는 적합하다.

//Database caches
//모든 DatabaseKit 기반 캐시는 구성된 DB를 캐시 저장소로 사용하여 지원한다.
//Vapor의 Fluent 매핑(FluentPostgreSQL, FluentMySQL 등) 및 데이터베이스 드라이버(PostgreSQL, MySQL, Redis 등)가 모두 포함된다.
//캐시된 데이터를 재 시작 시에도 유지하고, 응용 프로그램의 여러 인스턴스 간에 공유 할 수 있게 하려면 DB에 저장하는 것이 좋다.
//애플리케이션에 이미 DB가 구성되어 있다면 쉽게 설정할 수 있다.
//응용 프로그램의 기본 DB를 캐싱에 사용하거나 별도의 특수 DB를 사용할 수 있다.
//ex. 캐시에는 Redis DB를 사용하는 것이 일반적이다.

// • Redis
//Redis는 오픈 소스 캐시 Storage 서비스이다. 일반적으로 웹 응용 프로그램의 캐시 DB로 사용되며, Vapor Cloud, Heroku 등 대부분의 Deploy 서비스에서 지원된다.
//Redis DB는 구성하기 매우 쉽고 응용 프로그램을 다시 시작할 때 캐시 된 데이터를 유지하고 응용 프로그램의 여러 인스턴스 간에 캐시를 공유할 수 있다.




//API request에서 지연이 자주 발생한다. 통신하는 API 자체가 느릴 수 있고, 외부 API는 일정 시간 동안 사용자가 request할 수 있는 수와 속도에 제한을 주기도 한다.
//캐싱을 사용하면 이런 외부 API쿼리의 결과를 local에 저장하여 API를 훨씬 빠르게 사용할 수 있다.
