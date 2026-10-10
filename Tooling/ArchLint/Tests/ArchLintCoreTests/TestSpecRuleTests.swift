import Testing
@testable import ArchLintCore

// 테스트 명세 형식 규칙(test-spec-*) 자체 테스트.
// 검사 대상이 테스트 코드라 fixture도 테스트 코드 문자열이다.

private let enforcedPath = "/Projects/Domain/SampleDomain/Tests/UseCase/SampleUseCaseTests.swift"
private let otherDomainPath = "/Projects/Domain/OtherDomain/Tests/OtherTests.swift"
private let corePath = "/Projects/Core/Networking/Tests/NetworkingClientTests.swift"
private let rule = TestSpecRule(enforcedModules: ["SampleDomain", "Networking"])

private func lintTest(_ source: String, path: String = enforcedPath) -> [Violation] {
    lint(source: source, path: path, rules: [rule])
}

private func ruleIDs(_ violations: [Violation]) -> [String] {
    violations.map(\.ruleID).sorted()
}

@Suite("테스트 명세 형식 규칙")
struct TestSpecRuleTests {

    // MARK: - 스코프

    @Test("Tests 폴더의 Swift 파일에만 적용한다")
    func appliesOnlyToTestsFolder() {
        #expect(rule.applies(to: enforcedPath))
        #expect(!rule.applies(to: "/Projects/Domain/SampleDomain/Sources/Sample.swift"))
        #expect(!rule.applies(to: "/Projects/Domain/SampleDomain/Testing/Mock/MockSampleRepository.swift"))
    }

    @Test("규칙을 모두 지킨 테스트 파일에서는 위반이 없다")
    func reportsNothingForWellFormedTests() {
        let source = """
        @Suite("작품 평가")
        struct SampleTests {
            @Test("별점이 0.5 단위가 아니면 거절한다 (0.25 · 4.75)", arguments: [0.25, 4.75])
            func rejectsRatingNotInHalfSteps(_ value: Double) {
                #expect(Rating(value) == nil)
            }

            @Test("임시 저장본이 없으면 빈 초안을 돌려준다")
            func returnsEmptyDraftWithoutSavedDraft() async throws {
                let draft = try #require(await load())

                #expect(draft.isEmpty)
            }
        }

        extension SampleTests {
            private func makeDraft() -> Draft { Draft() }
        }
        """

        #expect(lintTest(source).isEmpty)
    }

    // MARK: - S1 test-suite-required

    @Test("파일 최상위에 둔 @Test를 잡는다")
    func catchesTopLevelTest() {
        let source = """
        @Test("별점을 저장한다")
        func savesRating() { #expect(true) }
        """

        #expect(ruleIDs(lintTest(source)) == ["test-suite-required"])
    }

    @Test("@Test를 담았는데 @Suite가 없는 타입을 잡는다")
    func catchesTypeWithTestsButNoSuite() {
        let source = """
        struct SampleTests {
            @Test("별점을 저장한다")
            func savesRating() { #expect(true) }
        }
        """

        #expect(ruleIDs(lintTest(source)) == ["test-suite-required"])
    }

    @Test("같은 파일에서 @Suite 없는 타입을 확장해 둔 @Test를 잡는다")
    func catchesTestsInExtensionOfTypeWithoutSuite() {
        let source = """
        struct SampleTests {}

        extension SampleTests {
            @Test("별점을 저장한다")
            func savesRating() { #expect(true) }
        }
        """

        let violations = lintTest(source)

        #expect(ruleIDs(violations) == ["test-suite-required"])
        #expect(violations.map(\.line) == [3])
    }

    // MARK: - S2 test-suite-name

    @Test("@Suite 표시 이름이 없거나 보간했거나 한국어가 아니면 잡는다", arguments: [
        "@Suite",
        "@Suite(.serialized)",
        #"@Suite("작품 \(kind)")"#,
        #"@Suite("Rating")"#,
    ])
    func catchesSuiteWithoutKoreanLiteralName(_ attribute: String) {
        let source = """
        \(attribute)
        struct SampleTests {
            @Test("별점을 저장한다")
            func savesRating() { #expect(true) }
        }
        """

        #expect(ruleIDs(lintTest(source)) == ["test-suite-name"])
    }

    @Test("@Suite 타입 이름이 Tests로 끝나지 않으면 잡는다")
    func catchesSuiteTypeNameWithoutTestsSuffix() {
        let source = """
        @Suite("작품 평가")
        struct RatingSpec {
            @Test("별점을 저장한다")
            func savesRating() { #expect(true) }
        }
        """

        #expect(ruleIDs(lintTest(source)) == ["test-suite-name"])
    }

    // MARK: - S3 test-name-sentence

    @Test("@Test 표시 이름이 없거나 보간했거나 한국어가 아니면 잡는다", arguments: [
        "@Test",
        "@Test(.tags(.critical))",
        #"@Test("\(value)점을 저장한다")"#,
        #"@Test("saves rating")"#,
    ])
    func catchesTestWithoutKoreanLiteralName(_ attribute: String) {
        let source = """
        @Suite("작품 평가")
        struct SampleTests {
            \(attribute)
            func savesRating() { #expect(true) }
        }
        """

        #expect(ruleIDs(lintTest(source)) == ["test-name-sentence"])
    }

    @Test("@Test 표시 이름이 '…다'로 끝나는 문장이 아니면 잡는다", arguments: [
        "별점 저장 성공",
        "중복된 닉네임",
        "별점을 저장한다 그리고",
    ])
    func catchesTestNameNotEndingAsSentence(_ name: String) {
        let source = """
        @Suite("작품 평가")
        struct SampleTests {
            @Test("\(name)")
            func savesRating() { #expect(true) }
        }
        """

        #expect(ruleIDs(lintTest(source)) == ["test-name-sentence"])
    }

    @Test("끝의 괄호 보충과 마침표는 떼고 '…다'를 본다", arguments: [
        "별점을 저장한다.",
        "별점을 저장한다 (0.5 단위)",
        "별점을 저장한다. (0.5 단위)",
        "별점을 저장한다(0.5 단위).",
        "별점을 저장한다 (반올림(0.25) 없음)",
    ])
    func acceptsSentenceWithTrailingSupplement(_ name: String) {
        let source = """
        @Suite("작품 평가")
        struct SampleTests {
            @Test("\(name)")
            func savesRating() { #expect(true) }
        }
        """

        #expect(lintTest(source).isEmpty)
    }

    // MARK: - S4 test-name-slash

    @Test("표시 이름에 '/'가 있으면 잡는다")
    func catchesSlashInDisplayName() {
        let source = """
        @Suite("딥링크/파싱")
        struct SampleTests {
            @Test("websoso://novels를 읽는다")
            func parsesNovelLink() { #expect(true) }
        }
        """

        #expect(ruleIDs(lintTest(source)) == ["test-name-slash", "test-name-slash"])
    }

    // MARK: - S5 test-name-duplicate

    @Test("같은 Suite 안에서 표시 이름이 겹치면 두 번째부터 잡는다")
    func catchesDuplicateDisplayNameInSameSuite() {
        let source = """
        @Suite("작품 평가")
        struct SampleTests {
            @Test("별점을 저장한다")
            func savesRating() { #expect(true) }

            @Test("별점을 저장한다")
            func savesRatingAgain() { #expect(true) }
        }

        extension SampleTests {
            @Test("별점을 저장한다")
            func savesRatingInExtension() { #expect(true) }
        }
        """

        let violations = lintTest(source)

        #expect(ruleIDs(violations) == ["test-name-duplicate", "test-name-duplicate"])
        #expect(violations.map(\.line) == [6, 11])
    }

    @Test("다른 Suite의 같은 표시 이름은 잡지 않는다")
    func allowsSameDisplayNameInDifferentSuites() {
        let source = """
        @Suite("작품 평가")
        struct RatingTests {
            @Test("빈 값이면 거절한다")
            func rejectsEmptyValue() { #expect(true) }
        }

        @Suite("읽은 기간")
        struct ReadingPeriodTests {
            @Test("빈 값이면 거절한다")
            func rejectsEmptyValue() { #expect(true) }
        }
        """

        #expect(lintTest(source).isEmpty)
    }

    @Test("다른 Suite에 중첩된 같은 이름의 타입은 같은 Suite로 보지 않는다")
    func distinguishesNestedTypesWithSameNameInDifferentSuites() {
        let source = """
        @Suite("작품 평가")
        struct RatingTests {
            @Suite("성공")
            struct SuccessTests {
                @Test("값을 돌려준다")
                func returnsValue() { #expect(true) }
            }
        }

        @Suite("읽은 기간")
        struct ReadingPeriodTests {
            @Suite("성공")
            struct SuccessTests {
                @Test("값을 돌려준다")
                func returnsValue() { #expect(true) }
            }
        }
        """

        #expect(lintTest(source).isEmpty)
    }

    @Test("중첩 타입을 경로로 확장한 extension의 중복도 잡는다")
    func catchesDuplicateInExtensionOfNestedType() {
        let source = """
        @Suite("작품 평가")
        struct RatingTests {
            @Suite("성공")
            struct SuccessTests {
                @Test("값을 돌려준다")
                func returnsValue() { #expect(true) }
            }
        }

        extension RatingTests.SuccessTests {
            @Test("값을 돌려준다")
            func returnsValueAgain() { #expect(true) }
        }
        """

        let violations = lintTest(source)

        #expect(ruleIDs(violations) == ["test-name-duplicate"])
        #expect(violations.map(\.line) == [11])
    }

    // MARK: - S6 test-assertion

    @Test("본문에 #expect나 #require가 없으면 warning으로 잡는다")
    func warnsTestWithoutAssertion() {
        let source = """
        @Suite("작품 평가")
        struct SampleTests {
            @Test("별점을 저장한다")
            func savesRating() async throws {
                try await sut.save(rating: 4.5)
            }
        }
        """

        let violations = lintTest(source)

        #expect(ruleIDs(violations) == ["test-assertion"])
        #expect(violations.allSatisfy { $0.severity == .warning })
    }

    // MARK: - W1 test-func-verb

    @Test("함수 이름이 3인칭 동사로 시작하는 영어 lowerCamelCase가 아니면 warning으로 잡는다", arguments: [
        "loadNovelSuccess",
        "sync_success_savesToLocalStorage",
        "SavesRating",
    ])
    func warnsFunctionNameNotStartingWithThirdPersonVerb(_ name: String) {
        let source = """
        @Suite("작품 평가")
        struct SampleTests {
            @Test("별점을 저장한다")
            func \(name)() { #expect(true) }
        }
        """

        let violations = lintTest(source)

        #expect(ruleIDs(violations) == ["test-func-verb"])
        #expect(violations.allSatisfy { $0.severity == .warning })
    }

    // MARK: - W2 test-name-vague

    @Test("표시 이름에 결과를 감추는 모호어가 있으면 warning으로 잡는다", arguments: [
        "작품 정보를 성공적으로 불러온다",
        "댓글 목록이 비어있어도 정상적으로 반환한다",
        "에러를 올바르게 변환한다",
        "초안을 제대로 저장한다",
    ])
    func warnsVagueWordInDisplayName(_ name: String) {
        let source = """
        @Suite("작품 평가")
        struct SampleTests {
            @Test("\(name)")
            func loadsNovel() { #expect(true) }
        }
        """

        let violations = lintTest(source)

        #expect(ruleIDs(violations) == ["test-name-vague"])
        #expect(violations.allSatisfy { $0.severity == .warning })
    }

    // MARK: - W3 test-name-identifier

    @Test("Domain 표시 이름에 메서드 · 프로퍼티 이름이 있으면 warning으로 잡는다", arguments: [
        "markAsInterested를 호출하면 관심 수가 늘어난다",
        "isInterested가 nil이면 상태가 바뀌지 않는다",
        "save()를 부르면 초안을 지운다",
    ])
    func warnsCodeIdentifierInDomainDisplayName(_ name: String) {
        let source = """
        @Suite("작품 관심")
        struct SampleTests {
            @Test("\(name)")
            func keepsState() { #expect(true) }
        }
        """

        let violations = lintTest(source)

        #expect(ruleIDs(violations) == ["test-name-identifier"])
        #expect(violations.allSatisfy { $0.severity == .warning })
    }

    @Test("타입 이름과 Domain · Feature 밖의 식별자는 잡지 않는다")
    func allowsTypeNamesAndIdentifiersOutsideDomainAndFeature() {
        let typeName = """
        @Suite("작품 관심")
        struct SampleTests {
            @Test("저장소가 실패하면 RepositoryError를 그대로 던진다")
            func rethrowsRepositoryError() { #expect(true) }
        }
        """
        let coreIdentifier = """
        @Suite("요청 조립")
        struct NetworkingClientTests {
            @Test("authorization이 withoutToken이면 Bearer 헤더를 붙이지 않는다")
            func omitsBearerHeaderWithoutToken() { #expect(true) }
        }
        """

        #expect(lintTest(typeName).isEmpty)
        #expect(lint(source: coreIdentifier, path: corePath, rules: [rule]).isEmpty)
    }

    // MARK: - 심각도

    @Test("S1 ~ S5는 적용 모듈에서 error이고, 적용하지 않은 모듈은 보고하지 않는다")
    func reportsOnlyEnforcedModulesWithStructuralErrors() {
        let source = """
        @Suite
        struct SampleTests {
            @Test("별점 저장")
            func savesRating() { #expect(true) }
        }
        """

        let enforced = lintTest(source)
        let other = lintTest(source, path: otherDomainPath)

        #expect(ruleIDs(enforced) == ["test-name-sentence", "test-suite-name"])
        #expect(enforced.allSatisfy { $0.severity == .error })
        #expect(other.isEmpty)
    }
}
