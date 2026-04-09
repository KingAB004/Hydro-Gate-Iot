(function () {
    const form = document.getElementById('admin-login-form');
    const emailInput = document.getElementById('admin-email');
    const passwordInput = document.getElementById('admin-password');
    const togglePasswordBtn = document.getElementById('toggle-password');
    const messageEl = document.getElementById('login-message');
    const submitBtn = document.getElementById('admin-login-submit');

    const setMessage = function (type, text) {
        if (!messageEl) return;
        messageEl.className = 'auth-message' + (type ? (' ' + type) : '');
        messageEl.textContent = text || '';
        messageEl.style.display = text ? '' : 'none';
    };

    const setLoading = function (isLoading) {
        if (submitBtn) submitBtn.disabled = !!isLoading;
        if (emailInput) emailInput.disabled = !!isLoading;
        if (passwordInput) passwordInput.disabled = !!isLoading;
        if (togglePasswordBtn) togglePasswordBtn.disabled = !!isLoading;

        if (submitBtn) {
            if (isLoading) submitBtn.classList.add('is-loading');
            else submitBtn.classList.remove('is-loading');
        }
    };

    const toRoleTag = function (role) {
        return (role || '').toString().trim().toUpperCase();
    };

    const isAdminRole = function (role) {
        const tag = toRoleTag(role);
        return tag === 'ADMIN' || tag === 'ADMINISTRATOR';
    };

    // Returns: true (admin) | false (not admin) | null (cannot verify)
    const ensureAdminRole = async function (user) {
        if (!user) return false;
        if (!window.firestoreDb) return null;

        try {
            const byUid = await window.firestoreDb.collection('users').doc(user.uid).get();
            if (byUid && byUid.exists) {
                const data = byUid.data() || {};
                return isAdminRole(data.role);
            }

            // Fallback for legacy data: look up by email field
            const email = (user.email || '').toString().trim();
            if (email) {
                const byEmail = await window.firestoreDb
                    .collection('users')
                    .where('email', '==', email)
                    .limit(1)
                    .get();

                if (byEmail && !byEmail.empty) {
                    const data = byEmail.docs[0].data() || {};
                    return isAdminRole(data.role);
                }
            }

            return false;
        } catch (err) {
            console.error('Failed to verify admin role:', err);
            return null;
        }
    };

    const redirectToDashboard = function () {
        window.location.replace('dashboard.html');
    };

    const init = function () {
        setMessage('', '');

        if (!window.firebase || !window.auth || !window.firestoreDb) {
            setMessage('error', 'Firebase is not initialized. Please reload the page.');
            return;
        }

        // Toggle password visibility
        if (togglePasswordBtn && passwordInput) {
            const renderToggleIcon = function (isVisible) {
                // Lucide replaces <i data-lucide> with <svg>, so re-render by resetting innerHTML.
                togglePasswordBtn.innerHTML = '<i data-lucide="' + (isVisible ? 'eye-off' : 'eye') + '" class="auth-toggle-icon"></i>';
                if (window.lucide && typeof window.lucide.createIcons === 'function') {
                    window.lucide.createIcons();
                }
                togglePasswordBtn.setAttribute('aria-pressed', isVisible ? 'true' : 'false');
            };

            renderToggleIcon(false);

            togglePasswordBtn.addEventListener('click', function () {
                try {
                    const currentType = passwordInput.getAttribute('type') || passwordInput.type;
                    const willShow = currentType === 'password';
                    passwordInput.setAttribute('type', willShow ? 'text' : 'password');
                    renderToggleIcon(willShow);
                    passwordInput.focus();
                } catch (err) {
                    console.error('Password visibility toggle failed:', err);
                }
            });
        }

        // Auto-redirect if already signed-in and admin
        window.auth.onAuthStateChanged(async function (user) {
            if (!user) return;
            const ok = await ensureAdminRole(user);
            if (ok === true) {
                redirectToDashboard();
                return;
            }

            if (ok === null) {
                setMessage('error', 'Unable to verify Admin role. Check Firestore access/rules for /users.');
            }

            // Not admin => sign out
            try {
                await window.auth.signOut();
            } catch (_) {}
        });

        if (form) {
            form.addEventListener('submit', async function (event) {
                event.preventDefault();

                const email = (emailInput ? emailInput.value : '').toString().trim();
                const password = (passwordInput ? passwordInput.value : '').toString();

                if (!email || !password) {
                    setMessage('warning', 'Please enter both email and password.');
                    return;
                }

                setLoading(true);
                setMessage('', '');

                try {
                    await window.auth.setPersistence(window.firebase.auth.Auth.Persistence.LOCAL);

                    const credential = await window.auth.signInWithEmailAndPassword(email, password);
                    const user = credential && credential.user;

                    const ok = await ensureAdminRole(user);
                    if (ok === null) {
                        try {
                            await window.auth.signOut();
                        } catch (_) {}
                        setMessage('error', 'Unable to verify Admin role. Check Firestore access/rules for /users.');
                        return;
                    }

                    if (ok === false) {
                        try {
                            await window.auth.signOut();
                        } catch (_) {}
                        setMessage('error', 'Access denied. This account is not an Admin.');
                        return;
                    }

                    redirectToDashboard();
                } catch (err) {
                    const code = err && err.code ? String(err.code) : '';
                    let message = 'Sign in failed. Please try again.';
                    if (code === 'auth/user-not-found') message = 'No user found for that email.';
                    else if (code === 'auth/wrong-password') message = 'Wrong password.';
                    else if (code === 'auth/invalid-email') message = 'Invalid email address.';
                    else if (err && err.message) message = String(err.message);

                    setMessage('error', message);
                } finally {
                    setLoading(false);
                }
            });
        }
    };

    if (document.readyState === 'loading') {
        document.addEventListener('DOMContentLoaded', init);
    } else {
        init();
    }
})();
