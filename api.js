const API_BASE = 'https://territoryx-api.onrender.com';

async function apiHeaders() {
  const token = (await _sb.auth.getSession()).data.session?.access_token;
  return { 'Content-Type': 'application/json', 'Authorization': 'Bearer ' + token };
}

async function adminLoadCreditApplications() {
  const container = document.getElementById('adminCreditApps');
  if (!container) return;
  container.innerHTML = '<div style="font-family:IBM Plex Mono;font-size:10px;color:var(--muted);padding:8px 0">Loading...</div>';
  try {
    const res = await fetch(API_BASE + '/api/admin/credit/applications', { headers: await apiHeaders() });
    const apps = await res.json();
    if (!apps || !apps.length) { container.innerHTML = '<div style="font-family:IBM Plex Mono;font-size:10px;color:var(--muted)">No pending applications</div>'; return; }
    container.innerHTML = apps.map(app => {
      const p = app.company_profile || {};
      return `<div style="padding:12px;background:rgba(0,242,254,0.03);border:1px solid var(--border);border-radius:3px;margin-bottom:8px">
        <div style="font-family:IBM Plex Mono;font-size:11px;font-weight:600;color:var(--text)">${p.company || 'Unknown'}</div>
        <div style="font-family:IBM Plex Mono;font-size:9px;color:var(--muted)">${p.email || ''} · ${p.country || ''}</div>
        <div style="display:flex;gap:8px;margin-top:8px">
          <button class="btn btn-primary btn-sm" onclick="adminReviewCredit('${app.user_id}', 'approve', ${app.credit_limit || 5000000})">APPROVE</button>
          <button class="btn btn-danger btn-sm" onclick="adminReviewCredit('${app.user_id}', 'reject', 0, prompt('Reason?') || '')">REJECT</button>
        </div>
      </div>`;
    }).join('');
  } catch (e) { container.innerHTML = '<div style="color:var(--red)">Error loading applications</div>'; }
}

async function adminReviewCredit(userId, action, limit, reason) {
  const url = `${API_BASE}/api/admin/credit/${userId}/${action}`;
  const body = action === 'approve' ? JSON.stringify({ limit }) : JSON.stringify({ reason });
  try {
    const res = await fetch(url, { method: 'POST', headers: await apiHeaders(), body });
    const data = await res.json();
    if (data.success) { showToast(action === 'approve' ? '✓ Approved' : 'Rejected', 'success'); adminLoadCreditApplications(); }
  } catch (e) { showToast('Failed: ' + e.message, 'err'); }
}

async function adminLoadUsers() {
  const list = document.getElementById('adminUserList');
  if (!list) return;
  try {
    const res = await fetch(API_BASE + '/api/admin/users', { headers: await apiHeaders() });
    const users = await res.json();
    list.innerHTML = users.map(u => `<div class="inv-row"><div class="inv-left"><div class="inv-num">${u.email}</div><div class="inv-meta">${u.company_name || ''}</div></div><div class="inv-status" style="border:1px solid ${u.role==='admin'?'var(--cyan)':'var(--green)'};color:${u.role==='admin'?'var(--cyan)':'var(--green)'};background:transparent">${u.role}</div></div>`).join('');
  } catch (e) { list.innerHTML = '<div style="color:var(--red)">Error</div>'; }
}

async function adminSetUserRole() {
  const email = document.getElementById('adminUserEmail').value.trim();
  const role = document.getElementById('adminUserRole').value;
  if (!email) return;
  try {
    const res = await fetch(API_BASE + '/api/admin/users', { headers: await apiHeaders() });
    const users = await res.json();
    const user = users.find(u => u.email === email);
    if (!user) { showToast('User not found', 'err'); return; }
    await fetch(`${API_BASE}/api/admin/users/${user.id}/role`, { method: 'PATCH', headers: await apiHeaders(), body: JSON.stringify({ role }) });
    showToast('✓ Role updated', 'success'); adminLoadUsers();
  } catch (e) { showToast('Failed: ' + e.message, 'err'); }
}

async function settleEpoch() {
  try {
    const res = await fetch(API_BASE + '/api/admin/epoch/settle', { method: 'POST', headers: await apiHeaders() });
    const data = await res.json();
    showToast('✓ EPOCH SETTLED', 'success'); renderAll();
  } catch (e) { showToast('Failed: ' + e.message, 'err'); }
}

async function adminLoadInvoices() {
  const list = document.getElementById('adminInvList');
  if (!list) return;
  try {
    const res = await fetch(API_BASE + '/api/admin/invoices', { headers: await apiHeaders() });
    const invs = await res.json();
    list.innerHTML = invs.map(i => `<div class="inv-row"><div class="inv-left"><div class="inv-num">${i.invoice_number}</div></div><div class="inv-amt">${fmtMoney(i.total)}</div><div class="inv-status ${i.status==='PAID'?'paid':i.status==='OVERDUE'?'overdue':'issued'}">${i.status}</div></div>`).join('');
  } catch (e) { list.innerHTML = '<div style="color:var(--red)">Error</div>'; }
}

async function adminLoadOverview() {
  try {
    const res = await fetch(API_BASE + '/api/admin/overview', { headers: await apiHeaders() });
    const data = await res.json();
    if (data.revenue) {
      document.getElementById('adminToll').textContent = fmtMoney(data.revenue.toll || 0);
      document.getElementById('adminLate').textContent = fmtMoney(data.revenue.late || 0);
      document.getElementById('adminTotal').textContent = fmtMoney(data.revenue.total || 0);
      document.getElementById('adminCollected').textContent = fmtMoney(data.revenue.collected || 0);
    }
  } catch (e) { console.warn('Overview failed', e); }
}

async function notifyAdminNewApplication(ca) {
  try {
    await fetch(API_BASE + '/api/notify/credit-application', { method: 'POST', headers: await apiHeaders(), body: JSON.stringify({ company: ca.companyProfile.company, limit: ca.estimatedLimit, email: ca.companyProfile.email, timestamp: ca.createdAt }) });
  } catch (e) {}
}

async function notifyUserCreditApproved(ca) {
  try {
    await fetch(API_BASE + '/api/notify/credit-approved', { method: 'POST', headers: await apiHeaders(), body: JSON.stringify({ to: ca.companyProfile.email, company: ca.companyProfile.company, limit: ca.limit }) });
  } catch (e) {}
}

async function notifyUserCreditRejected(ca) {
  try {
    await fetch(API_BASE + '/api/notify/credit-rejected', { method: 'POST', headers: await apiHeaders(), body: JSON.stringify({ to: ca.companyProfile.email, company: ca.companyProfile.company, reason: ca.rejectionReason }) });
  } catch (e) {}
}

async function downloadInvoicePDF(invId) {
  const a = document.createElement('a');
  a.href = `${API_BASE}/api/invoices/${invId}/pdf`;
  a.download = 'invoice.pdf';
  a.click();
}
