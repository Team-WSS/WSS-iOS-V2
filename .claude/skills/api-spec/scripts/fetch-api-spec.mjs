#!/usr/bin/env node
// 웹소소 서버 OpenAPI 명세를 받아 사람이 읽는 마크다운으로 출력한다.
//
// 사용:
//   node fetch-api-spec.mjs                 → 전체 엔드포인트 한 줄 목록
//   node fetch-api-spec.mjs collection      → 키워드(경로/태그/summary) 매칭 엔드포인트 상세
//   node fetch-api-spec.mjs --json          → 원본 OpenAPI JSON 그대로
//
// 스펙 URL은 WSS_SPEC_URL 환경변수로 덮어쓸 수 있다(운영 서버 등).
const SPEC_URL = process.env.WSS_SPEC_URL || 'https://dev.websoso.kr/swagger-ui/openapi3.json';

const args = process.argv.slice(2);
const wantJson = args.includes('--json');
const keyword = args.find((a) => !a.startsWith('--'));

const res = await fetch(SPEC_URL);
if (!res.ok) {
  console.error('스펙을 받지 못했습니다: ' + res.status + ' ' + SPEC_URL);
  process.exit(1);
}
const spec = await res.json();

if (wantJson) {
  console.log(JSON.stringify(spec, null, 2));
  process.exit(0);
}

// 이 명세는 서버의 Spring REST Docs 테스트로 생성된다 → 문서화 테스트가 있는 엔드포인트만 올라온다.
// 전체 개수를 늘 함께 보여줘야 "찾는 API가 없다 = 서버에 없다"는 오해를 막을 수 있다.
const endpoints = [];
const tagCount = {};
for (const [p, ops] of Object.entries(spec.paths)) {
  for (const [m, o] of Object.entries(ops)) {
    endpoints.push({ path: p, method: m, op: o });
    for (const t of o.tags || []) tagCount[t] = (tagCount[t] || 0) + 1;
  }
}
const tagSummary = Object.entries(tagCount)
  .map(([t, n]) => t + '(' + n + ')')
  .join(', ');

const coverageNote =
  '이 명세는 서버의 Spring REST Docs 테스트로 생성되어 **문서화된 엔드포인트만** 담긴다 (현재 총 ' +
  endpoints.length +
  '개: ' +
  tagSummary +
  ').\n여기 없다고 "서버에 없는 API"는 아니다 — 아직 문서화되지 않았을 뿐일 수 있으니 서버팀에 확인한다.';

if (!keyword) {
  console.log('# ' + (spec.info?.title || 'API') + ' — 엔드포인트 목록');
  console.log('출처: ' + SPEC_URL + '\n');
  console.log(coverageNote + '\n');
  for (const { path: p, method: m, op: o } of endpoints) {
    const tags = (o.tags || []).join(',');
    console.log('- ' + m.toUpperCase().padEnd(6) + p + '  — ' + (o.summary || '') + (tags ? '  [' + tags + ']' : ''));
  }
  process.exit(0);
}

const kw = keyword.toLowerCase();
const matches = (p, ops) =>
  p.toLowerCase().includes(kw) ||
  Object.values(ops).some((o) =>
    (o.tags || []).concat(o.summary || '').join(' ').toLowerCase().includes(kw),
  );

const deref = (o, seen = new Set()) => {
  if (!o || typeof o !== 'object') return o;
  if (o.$ref) {
    if (seen.has(o.$ref)) return { circular: o.$ref };
    let cur = spec;
    for (const k of o.$ref.replace(/^#\//, '').split('/')) cur = cur?.[k];
    return deref(cur, new Set([...seen, o.$ref]));
  }
  if (Array.isArray(o)) return o.map((x) => deref(x, seen));
  return Object.fromEntries(Object.entries(o).map(([k, v]) => [k, deref(v, seen)]));
};

// 필드 description에는 글자 수 제한·null 조건·정렬 순서 같은 정책이 들어 있고, Entity/DTO 주석과
// Domain 테스트 케이스가 여기서 나온다. 배열·중첩 객체 필드도 예외가 아니다
// (예: novelIds의 "배열 순서가 그대로 표시 순서로 저장된다") → 어느 분기에서도 description을 떨어뜨리지 않는다.
const shape = (s, ind = '') => {
  s = deref(s);
  if (!s) return ind + '?';

  const required = new Set(s.required || []);
  const line = (k, body, desc) =>
    ind + k + (required.has(k) ? '*' : '') + ': ' + body + (desc ? '  // ' + desc : '');

  if (s.properties) {
    return Object.entries(s.properties)
      .map(([k, v]) => {
        const t = deref(v);
        const desc = t.description || '';
        if (t.type === 'array') {
          const items = deref(t.items);
          if (items?.properties) {
            return line(k, '[{', desc) + '\n' + shape(items, ind + '  ') + '\n' + ind + '}]';
          }
          return line(k, '[' + (items?.type || '?') + ']', desc);
        }
        if (t.properties) {
          return line(k, '{', desc) + '\n' + shape(t, ind + '  ') + '\n' + ind + '}';
        }
        return line(k, t.type || '?', desc);
      })
      .join('\n');
  }

  if (s.type === 'array') {
    const items = deref(s.items);
    if (items?.properties) return ind + '[{\n' + shape(items, ind + '  ') + '\n' + ind + '}]';
    return ind + '[' + (items?.type || '?') + ']';
  }
  return ind + (s.type || '?');
};

// 서버가 requestBody를 application/json;charset=UTF-8 로 주는 경우가 있어 prefix 매칭이 필요하다.
// 'application/json'만 정확히 찾으면 요청 바디가 통째로 누락된다.
const jsonContent = (c) => {
  if (!c) return null;
  const k = Object.keys(c).find((x) => x.startsWith('application/json'));
  return k ? c[k] : null;
};

// examples의 value는 보통 JSON 문자열이지만 객체로 오는 경우도 있다 → [object Object] 방지.
const fmtExample = (v) => (typeof v === 'string' ? v : JSON.stringify(v));

const hits = Object.entries(spec.paths).filter(([p, ops]) => matches(p, ops));

if (hits.length === 0) {
  console.log('# "' + keyword + '" 와(과) 일치하는 엔드포인트가 없습니다.\n');
  console.log('출처: ' + SPEC_URL + '\n');
  console.log(coverageNote + '\n');
  console.log('다음으로 할 일:');
  console.log('1. 전체 목록을 눈으로 확인한다 (키워드가 서버 용어와 다를 수 있다)');
  console.log('   node .claude/skills/api-spec/scripts/fetch-api-spec.mjs');
  console.log('2. 그래도 없으면 기존 Data 모듈의 Endpoint/DTO 코드가 그 API의 진실 소스다');
  console.log('   ls Projects/Data/*/Sources/Endpoint/');
  process.exit(0);
}

const out = [];
out.push('# ' + (spec.info?.title || 'API') + ' — "' + keyword + '" 관련 엔드포인트');
out.push('\n출처: ' + SPEC_URL);
out.push('스키마의 `*` 표시는 required 필드다.\n');

for (const [p, ops] of hits) {
  for (const [m, o] of Object.entries(ops)) {
    out.push('\n---\n\n## ' + m.toUpperCase() + ' ' + p + ' — ' + (o.summary || '') + '\n');
    if (o.deprecated) out.push('> deprecated\n');

    // operation의 description에는 summary에 없는 운영 규칙이 들어 있다 —
    // "마이페이지 미리보기는 이 API를 size=3으로 호출해 구성한다", 커서 페이지네이션 절차,
    // 필드 간 관계(대표 작품이 recentNovels에 함께 내려간다) 같은, 화면 설계를 좌우하는 내용이다.
    if (o.description) {
      out.push(o.description.trim().split('\n').map((l) => '> ' + l).join('\n') + '\n');
    }

    if (o.parameters?.length) {
      out.push('**Parameters**\n');
      for (const x of o.parameters) {
        out.push('- ' + x.name + ' (' + x.in + (x.required ? ', required' : '') + ') — ' + (x.description || ''));
      }
      out.push('');
    }

    const rb = jsonContent(o.requestBody?.content);
    if (rb) {
      out.push('**Request**\n');
      out.push('```');
      out.push(shape(rb.schema));
      out.push('```');
      const ex = Object.values(rb.examples || {})[0]?.value;
      if (ex) out.push('예시: ' + fmtExample(ex) + '\n');
    }

    for (const [code, r] of Object.entries(o.responses || {})) {
      const c = jsonContent(r.content);
      if (!c) {
        out.push('**Response ' + code + '** — 본문 없음\n');
        continue;
      }
      out.push('**Response ' + code + '**\n');
      if (code.startsWith('2')) {
        out.push('```');
        out.push(shape(c.schema));
        out.push('```');
      }
      const exs = Object.values(c.examples || {});
      if (exs.length) out.push(exs.map((v) => '- ' + fmtExample(v.value)).join('\n') + '\n');
    }
  }
}

console.log(out.join('\n'));
