App.Pages = App.Pages || {};
App.Pages.AdminUsers = {
    async loadData() {
        const loading = document.getElementById('au-loading');
        const content = document.getElementById('au-content');
        if (loading) loading.classList.remove('hidden');
        if (content) content.classList.add('hidden');

        try {
            const res = await App.Api.get('/admin/users');
            const users = res.data || res || [];
            this.render(users);
        } catch (err) {
            if (loading) loading.innerHTML = '<p>Gagal memuat data</p>';
        }
    },

    render(users) {
        const loading = document.getElementById('au-loading');
        const content = document.getElementById('au-content');
        if (loading) loading.classList.add('hidden');
        if (content) content.classList.remove('hidden');
        if (!content) return;

        const securities = Array.isArray(users) ? users.filter((u) => u.role === 'security') : [];

        content.innerHTML = `
            <div class="flex-between mb-6">
                <div class="grid-2" style="flex:1;max-width:500px">
                    <div class="stat-card info">
                        <div class="stat-icon"><span class="material-icons-round">group</span></div>
                        <div class="stat-info">
                            <div class="stat-value">${Array.isArray(users) ? users.length : 0}</div>
                            <div class="stat-label">Total User</div>
                        </div>
                    </div>
                    <div class="stat-card blue">
                        <div class="stat-icon"><span class="material-icons-round">shield</span></div>
                        <div class="stat-info">
                            <div class="stat-value">${securities.length}</div>
                            <div class="stat-label">Security</div>
                        </div>
                    </div>
                </div>
                <button class="btn btn-primary" onclick="App.Pages.AdminUsers.addUserModal()">
                    <span class="material-icons-round">person_add</span> Tambah User
                </button>
            </div>

            <div class="card">
                <div class="card-header"><h3>Semua User</h3></div>
                <div class="card-body">
                    ${Array.isArray(users) && users.length > 0 ? `
                        <div class="table-container">
                            <table>
                                <thead><tr>
                                    <th>Nama</th><th>Username</th><th>Email</th><th>Role</th><th>Dibuat</th><th>Aksi</th>
                                </tr></thead>
                                <tbody>
                                    ${users.map((u) => `
                                        <tr>
                                            <td>
                                                <div style="display:flex;align-items:center;gap:10px">
                                                    <div style="width:34px;height:34px;border-radius:50%;background:var(--primary-light);display:flex;align-items:center;justify-content:center">
                                                        <span class="material-icons-round" style="font-size:18px;color:var(--primary)">person</span>
                                                    </div>
                                                    <strong>${u.name || '-'}</strong>
                                                </div>
                                            </td>
                                            <td>${u.username || '-'}</td>
                                            <td>${u.email || '-'}</td>
                                            <td><span class="badge ${({ admin: 'badge-red', security: 'badge-blue', driver: 'badge-green', staff: 'badge-yellow' })[u.role] || 'badge-gray'}">${u.role || '-'}</span></td>
                                            <td>${App.formatDate(u.created_at)}</td>
                                            <td>
                                                <div style="display:flex;gap:6px">
                                                    <button class="btn btn-outline btn-sm" onclick="App.Pages.AdminUsers.editUserModal(${u.id}, '${(u.name || '').replace(/'/g, "\\'")}', '${(u.username || '').replace(/'/g, "\\'")}', '${(u.email || '').replace(/'/g, "\\'")}', '${u.role || ''}')">
                                                        <span class="material-icons-round">edit</span>
                                                    </button>
                                                    <button class="btn btn-danger btn-sm" onclick="App.Pages.AdminUsers.deleteUser(${u.id}, '${(u.name || '').replace(/'/g, "\\'")}')">
                                                        <span class="material-icons-round">delete</span>
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    `).join('')}
                                </tbody>
                            </table>
                        </div>
                    ` : '<div class="empty-state"><span class="material-icons-round">group</span><p>Belum ada user</p></div>'}
                </div>
            </div>
        `;
    },

    addUserModal() {
        App.openModal(`
            <div class="modal-header"><h3>Tambah User Baru</h3><button class="modal-close" onclick="App.closeModal()"><span class="material-icons-round">close</span></button></div>
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label">Nama Lengkap</label>
                    <input type="text" class="form-input" id="u-name" required>
                </div>
                <div class="form-group">
                    <label class="form-label">Username</label>
                    <input type="text" class="form-input" id="u-username" required>
                </div>
                <div class="form-group">
                    <label class="form-label">Email</label>
                    <input type="email" class="form-input" id="u-email">
                </div>
                <div class="form-group">
                    <label class="form-label">Password</label>
                    <input type="password" class="form-input" id="u-password" required>
                </div>
                <div class="form-group">
                    <label class="form-label">Role</label>
                    <select class="form-select" id="u-role">
                        <option value="security">Security</option>
                        <option value="admin">Admin</option>
                        <option value="driver">Driver</option>
                        <option value="staff">Staff</option>
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-ghost" onclick="App.closeModal()">Batal</button>
                <button class="btn btn-primary" onclick="App.Pages.AdminUsers.submitUser()">Simpan</button>
            </div>
        `);
    },

    editUserModal(id, name, username, email, role) {
        App.openModal(`
            <div class="modal-header"><h3>Edit User</h3><button class="modal-close" onclick="App.closeModal()"><span class="material-icons-round">close</span></button></div>
            <div class="modal-body">
                <div class="form-group">
                    <label class="form-label">Nama Lengkap</label>
                    <input type="text" class="form-input" id="ue-name" value="${name}">
                </div>
                <div class="form-group">
                    <label class="form-label">Username</label>
                    <input type="text" class="form-input" id="ue-username" value="${username}">
                </div>
                <div class="form-group">
                    <label class="form-label">Email</label>
                    <input type="email" class="form-input" id="ue-email" value="${email}">
                </div>
                <div class="form-group">
                    <label class="form-label">Password Baru (kosongkan jika tidak ubah)</label>
                    <input type="password" class="form-input" id="ue-password">
                </div>
                <div class="form-group">
                    <label class="form-label">Role</label>
                    <select class="form-select" id="ue-role">
                        <option value="security" ${role === 'security' ? 'selected' : ''}>Security</option>
                        <option value="admin" ${role === 'admin' ? 'selected' : ''}>Admin</option>
                        <option value="driver" ${role === 'driver' ? 'selected' : ''}>Driver</option>
                        <option value="staff" ${role === 'staff' ? 'selected' : ''}>Staff</option>
                    </select>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-ghost" onclick="App.closeModal()">Batal</button>
                <button class="btn btn-primary" onclick="App.Pages.AdminUsers.updateUser(${id})">Update</button>
            </div>
        `);
    },

    async submitUser() {
        const data = {
            name: document.getElementById('u-name')?.value?.trim(),
            username: document.getElementById('u-username')?.value?.trim(),
            email: document.getElementById('u-email')?.value?.trim(),
            password: document.getElementById('u-password')?.value,
            role: document.getElementById('u-role')?.value,
        };
        if (!data.name || !data.username || !data.password) {
            App.toast('Nama, Username, dan Password wajib diisi', 'warning');
            return;
        }
        try {
            await App.Api.post('/admin/users', data);
            App.closeModal();
            App.toast('User berhasil ditambahkan!', 'success');
            App.Router.navigate('/admin/users');
        } catch (e) {
            App.toast('Gagal: ' + e.message, 'error');
        }
    },

    async updateUser(id) {
        const data = {
            name: document.getElementById('ue-name')?.value?.trim(),
            username: document.getElementById('ue-username')?.value?.trim(),
            email: document.getElementById('ue-email')?.value?.trim(),
            role: document.getElementById('ue-role')?.value,
        };
        const password = document.getElementById('ue-password')?.value;
        if (password) data.password = password;

        try {
            await App.Api.put('/admin/users/' + id, data);
            App.closeModal();
            App.toast('User berhasil diupdate!', 'success');
            App.Router.navigate('/admin/users');
        } catch (e) {
            App.toast('Gagal: ' + e.message, 'error');
        }
    },

    deleteUser(id, name) {
        App.openModal(`
            <div class="modal-header">
                <h3>Hapus User</h3>
                <button class="modal-close" onclick="App.closeModal()"><span class="material-icons-round">close</span></button>
            </div>
            <div class="modal-body">
                <div style="display:flex;align-items:flex-start;gap:16px">
                    <div style="width:48px;height:48px;border-radius:50%;background:#fee2e2;display:flex;align-items:center;justify-content:center;flex-shrink:0">
                        <span class="material-icons-round" style="color:#dc2626;font-size:24px">warning</span>
                    </div>
                    <div>
                        <p style="font-weight:600;margin:0 0 6px">Yakin ingin menghapus user ini?</p>
                        <p style="color:var(--text-secondary);margin:0;font-size:0.9rem">
                            User <strong>${name || 'ini'}</strong> akan dihapus secara permanen dan tidak dapat dikembalikan.
                        </p>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button class="btn btn-ghost" onclick="App.closeModal()">Batal</button>
                <button class="btn btn-danger" id="confirm-delete-btn" onclick="App.Pages.AdminUsers.confirmDelete(${id})">
                    <span class="material-icons-round" style="font-size:16px">delete</span> Hapus
                </button>
            </div>
        `);
    },

    async confirmDelete(id) {
        const btn = document.getElementById('confirm-delete-btn');
        if (btn) { btn.disabled = true; btn.innerHTML = 'Menghapus...'; }
        try {
            await App.Api.delete('/admin/users/' + id);
            App.closeModal();
            App.toast('User berhasil dihapus', 'success');
            App.Router.navigate('/admin/users');
        } catch (e) {
            App.toast('Gagal: ' + e.message, 'error');
            if (btn) { btn.disabled = false; btn.innerHTML = '<span class="material-icons-round" style="font-size:16px">delete</span> Hapus'; }
        }
    },
};
