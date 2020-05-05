/**
 * Dependencies
 */

import ReactorKit

/**
 * Reactor
 */

final class UserViewReactor: Reactor {

    // MARK: Constants

    // user actions
    enum Action {
        // inputs
        case updateFirstName(String)
        case validateFirstName(String)
        case updateLastName(String)
        case validateLastName(String)
        case updateEmail(String)
        case validateEmail(String)
        // extra
        case updateBio(String)
        case validateBio(String)
        // avatar
        case updateAvatar(Data)
        case deleteAvatar
        // default
        case done
    }

    // state changes
    enum Mutation {
        // inputs
        case updateFirstName(String)
        case updateLastName(String)
        case updateEmail(String)
        // extra
        case updateBio(String)
        // default
        case dismiss
        case setRefreshing(Bool)
        case success(String)
        case error(CustomError)
    }

    // the current view state
    struct State {
        var user: User
        var isDismissed: Bool
        var isRefreshing: Bool
        var errors: [DisplayError]

        init(user: User) {
            self.user = user
            self.isDismissed = false
            self.isRefreshing = false
            self.errors = []
        }
    }

    // MARK: Properties

    let provider: AppServicesProviderType
    let initialState: State

    // MARK: Initialization

    init(provider: AppServicesProviderType, user: User) {
        self.provider = provider
        self.initialState = State(user: user)
    }

    // MARK: Action -> Mutation (mutate() receives an Action and generates an Observable<Mutation>)

    func mutate(action: Action) -> Observable<Mutation> {
        switch action {
        // inputs
        case let .updateFirstName(firstName):
            return .just(.updateFirstName(firstName))
        case let .validateFirstName(section):
            switch currentState.user.validate(.firstname, section) {
            case .valid: return .just(.success("\(User.Validators.firstname)"))
            case let .invalid(err): return .just(.error(err[0] as! CustomError))
            }
        case let .updateLastName(lastName):
            return .just(.updateLastName(lastName))
        case let .validateLastName(section):
            switch currentState.user.validate(.lastname, section) {
            case .valid: return .just(.success("\(User.Validators.lastname)"))
            case let .invalid(err): return .just(.error(err[0] as! CustomError))
            }
        case let .updateEmail(email):
            return .just(.updateEmail(email))
        case let .validateEmail(section):
            switch currentState.user.validate(.email, section) {
            case .valid: return .just(.success("\(User.Validators.email)"))
            case let .invalid(err): return .just(.error(err[0] as! CustomError))
            }
        // extra
        case let .updateBio(bio):
            return .just(.updateBio(bio))
        case let .validateBio(section):
            switch currentState.user.validate(.bio, section) {
            case .valid: return .just(.success("\(User.Validators.bio)"))
            case let .invalid(err): return .just(.error(err[0] as! CustomError))
            }
        // avatar
        case let .updateAvatar(data):
            log.verbose("♻️ Action -> Mutation : update Avatar")
            return .concat([
                .just(.setRefreshing(true)),
                self.provider.userService
                    .updateAvatar(file: data, partName: "img", fileName: "test.\(data.imgExtension)", mimeType: data.mimeType)
                    .map { result in
                        switch result {
                        case .success: return .success("avatar updated")
                        case let .error(err): return .error(err)
                        }
                },
                .just(.setRefreshing(false))
            ])
        case .deleteAvatar:
            log.verbose("♻️ Action -> Mutation : delete Avatar")
            return .concat([
                .just(.setRefreshing(true)),
                self.provider.userService
                    .deleteAvatar()
                    .map { result in
                        switch result {
                        case .success: return .success("avatar deleted")
                        case let .error(err): return .error(err)
                        }
                },
                .just(.setRefreshing(false))
            ])
        // done
        case .done:
            return self.provider.userService
                .update(self.currentState.user)
                .map { result in
                    switch result {
                    case .success: return .dismiss
                    case let .error(err): return .error(err)
                    }
            }
        }
    }

    // MARK: Mutation -> State (reduce() generates a new State from a previous State and a Mutation)

    func reduce(state: State, mutation: Mutation) -> State {
        var state = state
        switch mutation {
        // inputs
        case let .updateFirstName(firstName):
            state.user.firstName = firstName
        case let .updateLastName(lastName):
            state.user.lastName = lastName
        case let .updateEmail(email):
            state.user.email = email
        // extra
        case let .updateBio(bio):
            state.user.bio = bio
        // refreshing
        case let .setRefreshing(isRefreshing):
            state.isRefreshing = isRefreshing
        // dissmiss
        case .dismiss:
            log.verbose("♻️ Mutation -> State : dismiss")
            state.isDismissed = true
            state.errors = []
        // success
        case let .success(success):
            log.verbose("♻️ Mutation -> State : succes \(success)")
            state.errors = purgeErrors(errors: state.errors, titles: [success, "Schema validation error", "jwt", "unknow"])
        // error
        case let .error(error):
            log.verbose("♻️ Mutation -> State : error \(error)")
            if error.code == 401 {
                self.provider.preferencesService.isLogged = false
                state.errors.insert(DisplayError(title: "jwt", description: "Wrong Password or Email."), at: 0)
            } else {
                if state.errors.firstIndex(where: { $0.title == error.message }) == nil {
                    state.errors.insert(DisplayError(title: error.message, description: error.description, type: error.type), at: 0)
                }
            }
        }
        return state
    }

}
