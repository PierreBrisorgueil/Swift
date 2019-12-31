/**
 * Dependencies
 */

import ReactorKit

/**
 * Reactor
 */

final class AuthSigninReactor: Reactor {

    // MARK: Constants

    // user actions
    enum Action {
        // inputs
        case updateEmail(String)
        case validateEmail
        case updatePassword(String)
        case updateIsFilled(Bool)
        // others
        case signIn
        case signUp
    }

    // state changes
    enum Mutation {
        // inputs
        case updateEmail(String)
        case updatePassword(String)
        case updateIsFilled(Bool)
        // others
        case goSignUp
        // default
        case success(String)
        case error(CustomError)
    }

    // the current view state
    struct State {
        var user: User
        var isFilled: Bool
        var errors: [DiplayError]

        init() {
            self.user = User()
            self.isFilled = false
            self.errors = []
        }
    }

    // MARK: Properties

    let provider: AppServicesProviderType
    let initialState: State

    // MARK: Initialization

    init(provider: AppServicesProviderType) {
        self.provider = provider
        self.initialState = State()
    }

    // MARK: Action -> Mutation (mutate() receives an Action and generates an Observable<Mutation>)

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        // email
        case let .updateEmail(email):
            return .just(.updateEmail(email))
        case .validateEmail:
            switch currentState.user.validate(.email) {
            case .valid: return .just(.success("\(User.Validators.email)"))
            case let .invalid(err): return .just(.error(err[0] as! CustomError))
            }
        // password 
        case let .updatePassword(password):
            return .concat(.just(.updatePassword(password)), .just(.success("password")))
        // form
        case let .updateIsFilled(isFilled):
            return .just(.updateIsFilled(isFilled))
        // signin
        case .signIn:
            log.verbose("♻️ Action -> Mutation : signIn(\(self.currentState.user.email))")
            return self.provider.authService
                .signIn(email: self.currentState.user.email, password: self.currentState.user.password ?? "")
                .map { result in
                    switch result {
                    case let .success(response):
                        UserDefaults.standard.set(response.tokenExpiresIn, forKey: "CookieExpire")
                        self.provider.preferencesService.isLogged = true
                        return .success("signIn")
                    case let .error(err): return .error(err)
                    }
            }
        // signup
        case .signUp:
            log.verbose("♻️ Action -> Mutation : signUp")
            return .just(.goSignUp)
        }
    }

    // MARK: Mutation -> State (reduce() generates a new State from a previous State and a Mutation)

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        // update login
        case let .updateEmail(email):
            state.user.email = email
        // update password
        case let .updatePassword(password):
            state.user.password = password
        // form
        case let .updateIsFilled(isFilled):
            state.isFilled = isFilled
        // go Signup
        case .goSignUp:
            log.verbose("♻️ Mutation -> State : goSignUp")
        // success
        case let .success(success):
            log.verbose("♻️ Mutation -> State : succes \(success)")
            if let index = state.errors.firstIndex(where: { $0.title == success }) {
                state.errors.remove(at: index)
            }
            if let index = state.errors.firstIndex(where: { $0.title == "Schema validation error" }) {
                state.errors.remove(at: index)  // purge server error after edit form
            }
            if let index = state.errors.firstIndex(where: { $0.title == "jwt" }) {
                state.errors.remove(at: index)  // purge jwt errors
            }
        // error
        case let .error(error):
            log.verbose("♻️ Mutation -> State : error \(error)")
            if error.code == 401 {
                self.provider.preferencesService.isLogged = false
                state.errors.insert(DiplayError(title: "jwt", description: "Wrong Password or Email."), at: 0)
            } else {
                if state.errors.firstIndex(where: { $0.title == error.message }) == nil {
                    state.errors.insert(DiplayError(title: error.message, description: (error.description ?? "Unknown error")), at: 0)
                }
            }
        }
        return state
    }

    // reactor init

    func signUpReactor() -> AuthSignUpReactor {
        return AuthSignUpReactor(provider: self.provider)
    }

}
