const { resolvePatrolAreaFromCode } = App.PatrolCore;

App.Pages = App.Pages || {};
App.Pages.Patrol = {
    scanner: null,
    scanning: false,
    scanCameraFacing: 'environment',
    captureStream: null,
    captureCameraFacing: 'environment',
    pendingArea: null,
    pendingBarcode: null,
    captureImages: [],

    async toggleScanner() {
        const area = document.getElementById('qr-scanner-area');
        const panel = document.getElementById('qr-scan-panel');
        const btn = document.getElementById('btn-start-scan');

        if (this.scanning) {
            await this.stopScanner();
            area.classList.add('hidden');
            if (panel) panel.classList.add('hidden');
            btn.innerHTML = '<span class="material-icons-round">camera_alt</span> Buka Kamera';
            this.scanning = false;
            this.updateScanSwitchButton();
            return;
        }

        if (panel) panel.classList.remove('hidden');
        area.classList.remove('hidden');
        btn.innerHTML = '<span class="material-icons-round">close</span> Tutup Kamera';
        this.scanning = true;
        this.updateScanSwitchButton();

        const isLocalhost = ['localhost', '127.0.0.1'].includes(window.location.hostname);
        if (!window.isSecureContext && !isLocalhost) {
            App.toast('Kamera di HP butuh HTTPS. Buka via URL https://', 'warning');
            area.classList.add('hidden');
            if (panel) panel.classList.add('hidden');
            btn.innerHTML = '<span class="material-icons-round">camera_alt</span> Buka Kamera';
            this.scanning = false;
            this.updateScanSwitchButton();
            return;
        }

        try {
            await this.startScannerSession();
        } catch (err) {
            const msg = err?.message || 'Gagal membuka kamera.';
            App.toast(msg, 'warning');
            area.classList.add('hidden');
            if (panel) panel.classList.add('hidden');
            btn.innerHTML = '<span class="material-icons-round">camera_alt</span> Buka Kamera';
            this.scanning = false;
            this.updateScanSwitchButton();
        }
    },

    async switchScanCamera() {
        this.scanCameraFacing = this.scanCameraFacing === 'environment' ? 'user' : 'environment';
        this.updateScanSwitchButton();
        if (!this.scanning) {
            return;
        }
        try {
            await this.stopScanner();
            await this.startScannerSession();
        } catch (err) {
            App.toast('Gagal ganti kamera scanner', 'warning');
        }
    },

    updateScanSwitchButton() {
        const btn = document.getElementById('btn-switch-scan-camera');
        if (!btn) return;
        btn.classList.toggle('hidden', !this.scanning);
        const targetLabel = this.scanCameraFacing === 'environment' ? 'Depan' : 'Belakang';
        btn.innerHTML = `<span class="material-icons-round">cameraswitch</span> ${targetLabel}`;
    },

    async resolveScanCameraConfig() {
        const desiredBack = this.scanCameraFacing === 'environment';
        let cameras = [];
        try {
            cameras = await Html5Qrcode.getCameras();
        } catch (e) {
            cameras = [];
        }

        if (Array.isArray(cameras) && cameras.length > 0) {
            const isBack = (label) => /back|rear|environment|belakang/i.test(label || '');
            const camera = desiredBack
                ? (cameras.find((c) => isBack(c.label)) || cameras[0])
                : (cameras.find((c) => !isBack(c.label)) || cameras[0]);
            return { deviceId: { exact: camera.id } };
        }

        return { facingMode: this.scanCameraFacing };
    },

    async startScannerSession() {
        this.scanner = new Html5Qrcode('qr-reader');
        const cameraConfig = await this.resolveScanCameraConfig();
        await this.scanner.start(
            cameraConfig,
            { fps: 10, qrbox: { width: 250, height: 250 } },
            (decodedText) => {
                this.handleScan(decodedText);
            },
            () => { }
        );
    },

    async stopScanner() {
        if (this.scanner) {
            try {
                await this.scanner.stop();
            } catch (e) { }
            try {
                await this.scanner.clear();
            } catch (e) { }
            this.scanner = null;
        }
    },

    async handleScan(code) {
        await this.stopScanner();
        this.scanning = false;
        this.updateScanSwitchButton();

        const area = document.getElementById('qr-scanner-area');
        if (area) area.classList.add('hidden');
        const panel = document.getElementById('qr-scan-panel');
        if (panel) panel.classList.add('hidden');

        const btn = document.getElementById('btn-start-scan');
        if (btn) btn.innerHTML = '<span class="material-icons-round">camera_alt</span> Buka Kamera';

        // Extract area label from the QR code (handles pipe-separated & plain text)
        const areaLabel = resolvePatrolAreaFromCode(code);
        if (!areaLabel) {
            App.toast('QR tidak valid. Gunakan QR Area Luar/Balkon/Smoking.', 'warning');
            return;
        }

        this.pendingArea = areaLabel;
        // Store the FULL raw QR string so backend can validate timestamp + HMAC
        this.pendingBarcode = code;
        await this.openCaptureModal();
    },

    async openCaptureModal() {
        const area = this.pendingArea || '-';
        const timestamp = new Date().toLocaleString('id-ID', {
            day: '2-digit',
            month: 'short',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        });

        this.resetCaptureImages();
        App.beforeCloseModal = () => this.stopCaptureCamera();
        App.openModal(`
            <div class="modal-header">
                <h3>Ambil Foto Patroli</h3>
                <button class="modal-close" onclick="App.Pages.Patrol.closeCaptureModal()">
                    <span class="material-icons-round">close</span>
                </button>
            </div>
            <div class="modal-body">
                <div style="background:var(--gray-50);border:1px solid var(--gray-200);border-radius:12px;padding:12px;margin-bottom:12px">
                    <div style="font-size:12px;color:var(--gray-500);font-weight:600">AREA</div>
                    <div style="font-size:18px;font-weight:700">${area}</div>
                    <div style="font-size:12px;color:var(--gray-500);margin-top:4px">Waktu perangkat: ${timestamp}</div>
                </div>
                <video id="patrol-live-video" autoplay playsinline muted
                    style="width:100%;border-radius:12px;border:1px solid var(--gray-200);background:#000;max-height:420px;object-fit:cover"></video>
                <div class="flex-between" style="margin-top:10px;gap:12px;flex-wrap:wrap">
                    <div id="patrol-capture-count" style="font-size:12px;color:var(--gray-600);font-weight:600">
                        Foto: 0/2 (wajib 2 foto)
                    </div>
                    <div style="display:flex;gap:8px;flex-wrap:wrap">
                        <button class="btn btn-ghost btn-sm" id="btn-switch-capture-camera" onclick="App.Pages.Patrol.switchCaptureCamera()">
                            <span class="material-icons-round">cameraswitch</span> Ke Kamera Depan
                        </button>
                        <button class="btn btn-ghost btn-sm" onclick="App.Pages.Patrol.resetCaptureImages()">
                            <span class="material-icons-round">refresh</span> Ulangi
                        </button>
                    </div>
                </div>
                <div id="patrol-capture-preview" style="display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:10px;margin-top:10px"></div>
                <p style="font-size:12px;color:var(--gray-500);margin-top:10px">
                    Ambil foto langsung dari kamera. Upload file dari galeri tidak tersedia.
                </p>
            </div>
            <div class="modal-footer">
                <button class="btn btn-ghost" onclick="App.Pages.Patrol.closeCaptureModal()">Batal</button>
                <button class="btn btn-outline" id="btn-capture-patrol" onclick="App.Pages.Patrol.capturePhoto()">
                    <span class="material-icons-round">photo_camera</span> Ambil Foto
                </button>
                <button class="btn btn-primary" id="btn-save-patrol" onclick="App.Pages.Patrol.submitCapturedPatrol()" disabled>
                    <span class="material-icons-round">save</span> Simpan Patroli
                </button>
            </div>
        `);

        this.updateCaptureUi();
        this.updateCaptureSwitchButton();
        await this.startCaptureCamera();
    },

    closeCaptureModal() {
        this.stopCaptureCamera();
        this.resetCaptureImages();
        App.beforeCloseModal = null;
        App.closeModal();
    },

    async switchCaptureCamera() {
        this.captureCameraFacing = this.captureCameraFacing === 'environment' ? 'user' : 'environment';
        this.updateCaptureSwitchButton();
        if (!document.getElementById('patrol-live-video')) return;
        await this.startCaptureCamera();
    },

    updateCaptureSwitchButton() {
        const btn = document.getElementById('btn-switch-capture-camera');
        if (!btn) return;
        const targetLabel = this.captureCameraFacing === 'environment' ? 'Ke Kamera Depan' : 'Ke Kamera Belakang';
        btn.innerHTML = `<span class="material-icons-round">cameraswitch</span> ${targetLabel}`;
    },

    async startCaptureCamera() {
        const video = document.getElementById('patrol-live-video');
        if (!video) return;

        try {
            this.stopCaptureCamera();
            this.captureStream = await navigator.mediaDevices.getUserMedia({
                audio: false,
                video: {
                    facingMode: { ideal: this.captureCameraFacing },
                    width: { ideal: 1280 },
                    height: { ideal: 720 }
                }
            });
            video.srcObject = this.captureStream;
            await video.play();
        } catch (e) {
            App.toast('Tidak bisa membuka kamera foto. Cek izin kamera browser.', 'error');
            this.closeCaptureModal();
        }
    },

    stopCaptureCamera() {
        if (this.captureStream) {
            this.captureStream.getTracks().forEach((track) => track.stop());
            this.captureStream = null;
        }
        const video = document.getElementById('patrol-live-video');
        if (video) video.srcObject = null;
    },

    resetCaptureImages() {
        this.captureImages.forEach((img) => {
            if (img?.url) URL.revokeObjectURL(img.url);
        });
        this.captureImages = [];
        this.updateCaptureUi();
    },

    updateCaptureUi() {
        const countEl = document.getElementById('patrol-capture-count');
        if (countEl) {
            countEl.textContent = `Foto: ${this.captureImages.length}/2 (wajib 2 foto)`;
        }

        const preview = document.getElementById('patrol-capture-preview');
        if (preview) {
            preview.innerHTML = this.captureImages.map((img, idx) => `
                <div style="border:1px solid var(--gray-200);border-radius:10px;overflow:hidden;background:#fff">
                    <img src="${img.url}" alt="Patrol capture ${idx + 1}" style="width:100%;height:140px;object-fit:cover;display:block">
                    <div style="padding:6px 8px;font-size:11px;color:var(--gray-600);font-weight:600">Foto ${idx + 1}</div>
                </div>
            `).join('');
        }

        const captureBtn = document.getElementById('btn-capture-patrol');
        if (captureBtn) {
            captureBtn.disabled = this.captureImages.length >= 2;
        }

        const saveBtn = document.getElementById('btn-save-patrol');
        if (saveBtn) {
            saveBtn.disabled = this.captureImages.length < 2;
        }
    },

    async capturePhoto() {
        const area = this.pendingArea;
        const video = document.getElementById('patrol-live-video');

        if (!area || !video) {
            App.toast('Data scan tidak lengkap. Scan ulang QR.', 'warning');
            return;
        }
        if (!this.captureStream) {
            App.toast('Kamera foto belum aktif.', 'warning');
            return;
        }
        if (this.captureImages.length >= 2) {
            App.toast('Maksimal 2 foto untuk satu area patroli', 'warning');
            return;
        }

        try {
            const width = video.videoWidth || 1280;
            const height = video.videoHeight || 720;
            const canvas = document.createElement('canvas');
            canvas.width = width;
            canvas.height = height;

            const ctx = canvas.getContext('2d');
            ctx.drawImage(video, 0, 0, width, height);

            const stampText = `${area} | ${new Date().toLocaleString('id-ID')}`;
            ctx.fillStyle = 'rgba(0,0,0,0.55)';
            ctx.fillRect(0, height - 46, width, 46);
            ctx.fillStyle = '#ffffff';
            ctx.font = '600 18px Inter, sans-serif';
            ctx.textAlign = 'left';
            ctx.fillText(stampText, 14, height - 16);

            const blob = await new Promise((resolve) => canvas.toBlob(resolve, 'image/jpeg', 0.9));
            if (!blob) throw new Error('Gagal mengambil frame kamera');
            const url = URL.createObjectURL(blob);
            this.captureImages.push({ blob, url });
            this.updateCaptureUi();
            App.toast(`Foto ${this.captureImages.length}/2 berhasil diambil`, 'success');
        } catch (e) {
            App.toast('Gagal mengambil foto: ' + e.message, 'error');
        }
    },

    async submitCapturedPatrol() {
        const area = this.pendingArea;
        const barcode = this.pendingBarcode || this.pendingArea || '-';
        const saveBtn = document.getElementById('btn-save-patrol');
        if (!area) {
            App.toast('Area patroli tidak ditemukan. Scan ulang QR.', 'warning');
            return;
        }
        if (this.captureImages.length < 2) {
            App.toast('Wajib ambil 2 foto dulu sebelum simpan patroli', 'warning');
            return;
        }

        try {
            if (saveBtn) {
                saveBtn.disabled = true;
                saveBtn.innerHTML = '<div class="spinner" style="margin:auto"></div>';
            }

            const formData = new FormData();
            formData.append('area', area);
            formData.append('barcode', barcode);
            this.captureImages.forEach((img, idx) => {
                formData.append('photos[]', img.blob, `patrol-${Date.now()}-${idx + 1}.jpg`);
            });

            await App.Api.postFormData('/patrols', formData);
            this.closeCaptureModal();
            App.toast(`Patroli ${area} berhasil disimpan (2 foto)`, 'success');
            setTimeout(() => App.Router.navigate('/patrol'), 400);
        } catch (e) {
            App.toast('Gagal menyimpan patroli: ' + e.message, 'error');
            if (saveBtn) {
                saveBtn.disabled = false;
                saveBtn.innerHTML = '<span class="material-icons-round">save</span> Simpan Patroli';
            }
        }
    },

    showConditionLocked() {
        const message = this.conditionGate?.message
            || 'Selesaikan 3 area untuk satu sesi sebelum membuat laporan kondisi.';
        App.toast(message, 'warning');
    },

    openConditionForm() {
        if (this.conditionGate && !this.conditionGate.canCreateCondition) {
            this.showConditionLocked();
            return;
        }
        const nowTime = new Date().toTimeString().slice(0, 5);
        App.openModal(`
            <div class="modal-header">
                <h3>Laporan Kondisi Area</h3>
                <button class="modal-close" onclick="App.closeModal()">
                    <span class="material-icons-round">close</span>
                </button>
            </div>
            <div class="modal-body">
                <form id="condition-form">
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">Tanggal</label>
                            <input type="date" class="form-input" id="cond-date" value="${new Date().toISOString().split('T')[0]}" required>
                        </div>
                        <div class="form-group">
                            <label class="form-label">Waktu</label>
                            <input type="time" class="form-input" id="cond-time" value="${nowTime}" required>
                        </div>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Situasi</label>
                        <input type="text" class="form-input" id="cond-situasi" placeholder="Deskripsi situasi" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">AGHT</label>
                        <input type="text" class="form-input" id="cond-aght" placeholder="AGHT" required>
                    </div>
                    <div class="form-group">
                        <label class="form-label">Cuaca</label>
                        <select class="form-select" id="cond-cuaca" required>
                            <option value="cerah">Cerah</option>
                            <option value="berawan">Berawan</option>
                            <option value="mendung">Mendung</option>
                            <option value="hujan">Hujan</option>
                            <option value="hujan_lebat">Hujan Lebat</option>
                        </select>
                    </div>
                    <div class="form-row">
                        <div class="form-group">
                            <label class="form-label">PDAM (opsional)</label>
                            <input type="text" class="form-input" id="cond-pdam" placeholder="Status PDAM">
                        </div>
                        <div class="form-group">
                            <label class="form-label">WFO</label>
                            <input type="number" class="form-input" id="cond-wfo" value="0" min="0">
                        </div>
                        <div class="form-group">
                            <label class="form-label">Tambahan</label>
                            <input type="number" class="form-input" id="cond-tambahan" value="0" min="0">
                        </div>
                    </div>
                </form>
            </div>
            <div class="modal-footer">
                <button class="btn btn-ghost" onclick="App.closeModal()">Batal</button>
                <button class="btn btn-primary" onclick="App.Pages.Patrol.submitCondition()">
                    <span class="material-icons-round">save</span> Simpan
                </button>
            </div>
        `);
    },

    async submitCondition() {
        const date = document.getElementById('cond-date')?.value;
        const time = document.getElementById('cond-time')?.value;
        const situasi = document.getElementById('cond-situasi')?.value?.trim();
        const aght = document.getElementById('cond-aght')?.value?.trim();
        const cuaca = document.getElementById('cond-cuaca')?.value;
        const pdam = document.getElementById('cond-pdam')?.value?.trim() || null;
        const wfo = parseInt(document.getElementById('cond-wfo')?.value) || 0;
        const tambahan = parseInt(document.getElementById('cond-tambahan')?.value) || 0;

        if (!date || !time || !situasi || !aght || !cuaca) {
            App.toast('Tanggal, Waktu, Situasi, AGHT, dan Cuaca wajib diisi', 'warning');
            return;
        }

        try {
            await App.Api.post('/patrol-conditions', { date, time, situasi, aght, cuaca, pdam, wfo, tambahan });
            App.closeModal();
            App.toast('Laporan kondisi berhasil disimpan', 'success');
            setTimeout(() => App.Router.navigate('/patrol'), 300);
        } catch (e) {
            App.toast('Gagal menyimpan: ' + e.message, 'error');
        }
    },
};
