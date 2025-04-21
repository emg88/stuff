both scripts update tor when the installed package says obsolete. will fix so you're able to get newer version of tor to run a relay or exit.


### **updatetorroot.sh**

#### **Description**:
`updatetorroot.sh` is designed for users with root privileges to securely resolve GPG key issues, configure the Tor repository, and install the latest Tor version system-wide. The script ensures all changes affect the entire system, making it suitable for server administrators or those with full system access.

#### **How It Works**:
- Adds the Tor Project's GPG key to the system-wide keyring.
- Configures the Tor repository by creating a new file in `/etc/apt/sources.list.d/`.
- Runs APT commands (`apt update` and `apt install`) with root privileges to fetch and install the latest Tor version.
- Verifies the installation by checking the Tor version.

#### **Ideal Use Case**:
For users who have root privileges and want a system-wide installation or update of Tor that applies to all system users.

---

### **updatetorsudo.sh**

#### **Description**:
`updatetorsudo.sh` (updates tor when it says OBSOLETE), caters to environments where the user lacks root privileges. It operates entirely within the user space, leveraging local directories for GPG keys, repository configurations, and package management. The script avoids modifying system-wide configurations, making it an ideal solution for shared systems.

#### **How It Works**:
- Stores the Tor Project's GPG key in a directory within the user's home directory.
- Configures a local repository file in the user's home directory, avoiding system-wide changes.
- Sets up APT to use user-defined cache and state directories with environment variables.
- Installs the latest Tor version in user space without requiring administrative rights.
- Verifies the installation by checking the locally installed version of Tor.

#### **Ideal Use Case**:
For users operating in environments where they lack administrative privileges or need a user-specific installation without affecting other system users.

---

### **Comparison Between the Scripts**

| Feature                     | `updatetorroot.sh`           | `updatetorsudo.sh`           |
|-----------------------------|------------------------------|------------------------------|
| **Access Required**          | Root privileges              | No root access required      |
| **Keyring Location**         | System-wide directory        | User-specific directory      |
| **Repository Configuration** | `/etc/apt/sources.list.d/`   | Local file in home directory |
| **Scope**                    | System-wide                 | User-specific                |
| **APT Commands**             | System-wide (`apt`)          | Localized with environment variables |

---

