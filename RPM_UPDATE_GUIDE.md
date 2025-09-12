# How to Update the Squeeze RPM Package

This file contains two guides: one for fully automated releases using GitHub Actions, and one for creating manual local builds.

---

## Guide 1: Automated Releases (Recommended)

This is the preferred method for creating public releases. The process is automated by a GitHub Actions workflow that triggers when you push a new version tag.

### Step 1: Commit Your Code

Make sure all your application changes are committed to Git.

### Step 2: Update Version and Create Tag

1.  **Update the version** in `pubspec.yaml`. For example, change `1.0.1+2` to `1.0.2+3`.

2.  **Commit this version change**:
    ```bash
    git add pubspec.yaml
    git commit -m "Bump version to 1.0.2+3"
    ```

3.  **Create an annotated Git tag**. The tag name **must** start with `v` and match the version in `pubspec.yaml`. The message you provide with `-m` will become the official release notes.
    ```bash
    # Format: git tag -a v<version> -m "Your release notes"
    git tag -a v1.0.2+3 -m "This release fixes the re-processing bug and adds automated builds."
    ```

### Step 3: Push to GitHub

Push your commit and the new tag to GitHub. This will automatically trigger the release workflow.

```bash
git push && git push --tags
```

### Step 4: Check the Release

That's it! Go to the "Actions" tab in your GitHub repository to monitor the progress. Once it completes, a new GitHub Release will be created, with the `.rpm` file automatically built and attached.

---

## Guide 2: Manual Local Builds (All Platforms)

Follow these steps if you need to create a local test build for any platform without making a public release. This uses the `fastforge` tool.

### Step 1: Install fastforge

If you haven't already, install `fastforge` on your machine.

```bash
dart pub global activate fastforge
```

### Step 2: Build the App

Run the `fastforge build` command, specifying the release name from `distribute_options.yaml` that you want to build (`linux`, `windows`, or `macos`).

```bash
# To build all Linux packages (.rpm, .deb, .AppImage)
fastforge build linux

# To build the Windows installer (.msix)
fastforge build windows

# To build the macOS package (.zip)
fastforge build macos
```

### Step 3: Find the Installers

After the build succeeds, you will find all the generated installers inside the `dist/` directory.

---

## Appendix: Old Manual RPM Build (Legacy)

Follow these steps only if the `fastforge` tool fails and you need to build an RPM package manually.


**Run all commands from the project's root directory** (`/home/ramy/Developement/flutter_projects/flutter_desktop/squeeze`).

### Step 1: Update Application Version

Before you begin, decide on the new version number.

1.  Open the `pubspec.yaml` file.
2.  Increment the `version` line. For example:
    ```yaml
    # Before
    version: 1.0.1+2

    # After
    version: 1.0.2+3
    ```

### Step 2: Build the Linux Release

Create a new release build of the Flutter application. This command bundles your updated Dart code into executable files.

```bash
flutter build linux --release
```

### Step 3: Copy the New Build Files

Replace the old application files in the `rpmbuild` structure with the new ones you just built. The `rsync` command is perfect for this as it will cleanly synchronize the directories.

```bash
rsync -a --delete build/linux/x64/release/bundle/ dist/1.0.0+1/squeeze-1.0.0+1-linux_rpm/rpmbuild/BUILD/squeeze/
```

### Step 4: Update the `squeeze.spec` File

This is the blueprint for the RPM. You need to tell it about the new version.

1.  Open the file: `dist/1.0.0+1/squeeze-1.0.0+1-linux_rpm/rpmbuild/SPECS/squeeze.spec`

2.  **Update the Version:** Change the `Version:` tag to match the new version you set in `pubspec.yaml`.

    ```spec
    # Before
    Version: 1.0.1+2

    # After
    Version: 1.0.2+3
    ```

3.  **Add a Changelog Entry:** Add a new entry to the **top** of the `%changelog` section. It's critical that new entries go above old ones.

    **Template:**
    ```spec
    * [Current Date] Your Name <your@email.com> - [New Version]-1
    - A brief description of the changes in this version.
    ```

    **Example:**
    ```spec
    %changelog
    * Fri Sep 12 2025 Ramy <you@example.com> - 1.0.2+3-1
    - Added a new feature for batch renaming files.
    * Fri Sep 12 2025 Ramy you@example.com - 1.0.1+2-1
    - Fixed an issue where the process doesn't work after the initial start.
    * Fri Sep 13 2024 Ramy you@example.com - 1.0.0+1-1
    - Initial package
    ```

### Step 5: Build the New RPM

Run the `rpmbuild` command. This command includes the necessary flags to find your files correctly and to ignore the `runpath` errors that are common with Flutter builds.

```bash
QA_RPATHS=0x0002 rpmbuild -ba --define "_topdir $(pwd)/dist/1.0.0+1/squeeze-1.0.0+1-linux_rpm/rpmbuild" dist/1.0.0+1/squeeze-1.0.0+1-linux_rpm/rpmbuild/SPECS/squeeze.spec
```

### Step 6: Install the Updated Package

After the command in Step 5 succeeds, your new RPM will be created.

1.  **Locate the new RPM file.** It will be located at:
    `dist/1.0.0+1/squeeze-1.0.0+1-linux_rpm/rpmbuild/RPMS/x86_64/`

2.  **Install the update** using the `rpm -U` command. Remember to replace `<new_version>` with the actual version number.

    ```bash
    # Example command
    sudo rpm -U dist/1.0.0+1/squeeze-1.0.0+1-linux_rpm/rpmbuild/RPMS/x86_64/squeeze-1.0.2+3-1.fc42.x86_64.rpm
    ```
