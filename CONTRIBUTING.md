# Contributing

We follow a simple model to make contributing as straightforward as possible. These guidelines allow us to streamline the development process and achieve greater transparency.

## Proposing changes

The `main` branch is protected and cannot be committed to directly. It will always contain the latest version of the project that is considered to be stable. Development happens on the `dev` branch. In order to propose a change to the project, we have the following process:

1. Fork the repository if you do not have write access.
2. Create a branch from `dev`, using the following naming convention:
    1. `feat/feature-name` when introducing a new feature.
    2. `fix/fix-name` when fixing an existing issue.
	3. `chore/chore-dec` for miscellaneous changes.
3. Stick to the project coding style. ([See below](#coding-style).)
4. Add your commits to the branch following Conventional Commits ([See below](#conventional-commits).)
5. Open a Pull Request targeting the `dev` branch and tag the right code owners for review. ([See below](#code-owners).)
6. Merge the PR into `dev` if you have write access or request a merge from a code owner after reviews and checks have passed.

Note that any new code must be covered by unit tests. Only PRs with checks successfully are eligible to be merged. The code owners reserve the right to accept or reject PRs.

Any contributions that are accepted become part of the code base under the same [license](LICENSE) that covers the project.

## Opening issues

You can open an issue via GitHub's issue tracker. You may tag one or more code owners for visibility if you think it fits the issue.

## Coding style

- Tabs instead of spaces.
- Closing brackets generally go on a new line.

## Conventional Commits

We follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) standard for commit messages. The pattern for such a commit message is as follows:
```
type(scope?): description
```

Where `type` is one of:

- `feat`: commits that add a feature.
- `fix`: commits that fix an issue.
- `refactor`: commits that (re)write code but do not change behaviour.
- `chore`: miscellaneous commits or housekeeping.
- Or one of the other types described by the standard.

The `scope` portion is optional and valid options depend on the project.

Example Conventional Commit message:
```
fix(yield-token): unwrap memo and print if not none
```

## Code owners

All repositories should contain a `CODEOWNERS` file that automatically requests the right code owner(s) for review when a new PR is submitted. If it does not happen, or if you think someone else should be included, you can request a review manually.
