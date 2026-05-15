const test = require('node:test');
const assert = require('node:assert/strict');
const { ensureTripUserInCity } = require('../trips/modules/trips/trips.repository');

const USER_ID = '9D4CC8F9-7A5C-4A53-8F18-6DF42A60B111';

function createUser(city = 'HCM') {
  return {
    id: USER_ID,
    ho_ten: 'Khách Demo',
    email: 'khach.demo@example.com',
    mat_khau: 'hashed-password',
    so_dien_thoai: '0900000000',
    thanh_pho: city,
    vai_tro: 'user',
  };
}

function createDeps(initialUsers, options = {}) {
  const stores = {
    HCM: [...(initialUsers.HCM || [])],
    HN: [...(initialUsers.HN || [])],
  };
  const inserts = [];
  const calls = [];

  function makePool(city) {
    return {
      request() {
        const params = {};
        return {
          input(name, _typeOrValue, maybeValue) {
            params[name] = arguments.length === 3 ? maybeValue : _typeOrValue;
            return this;
          },
          async query(queryText) {
            if (queryText.includes('INSERT INTO users')) {
              if (options.readOnlyCity === city) {
                const error = new Error('Chỉ xem được dữ liệu');
                error.code = 'READ_ONLY_MODE';
                throw error;
              }

              const user = {
                id: params.id,
                ho_ten: params.ho_ten,
                email: params.email,
                mat_khau: params.mat_khau,
                so_dien_thoai: params.so_dien_thoai,
                thanh_pho: params.thanh_pho,
                vai_tro: params.vai_tro,
              };
              stores[city].push(user);
              inserts.push({ city, user });
              return { recordset: [] };
            }

            if (queryText.includes('mat_khau')) {
              const user = stores[city].find((item) => item.id === params.id);
              return { recordset: user ? [user] : [] };
            }

            if (queryText.includes('FROM users')) {
              const user = stores[city].find((item) => item.id === params.id);
              return { recordset: user ? [{ id: user.id }] : [] };
            }

            throw new Error(`Unexpected query: ${queryText}`);
          },
        };
      },
    };
  }

  return {
    stores,
    inserts,
    calls,
    deps: {
      async getPrimaryConnection(city) {
        calls.push({ type: 'primary', city });
        return makePool(city);
      },
      async getWritablePrimaryConnection(city) {
        calls.push({ type: 'writable', city });
        return makePool(city);
      },
    },
  };
}

test('ensureTripUserInCity không insert lại nếu user đã có ở DB đích', async () => {
  const { inserts, deps } = createDeps({
    HCM: [createUser('HCM')],
    HN: [createUser('HN')],
  });

  const result = await ensureTripUserInCity({
    userId: USER_ID,
    sourceCity: 'HCM',
    targetCity: 'HN',
  }, deps);

  assert.equal(result.created, false);
  assert.equal(inserts.length, 0);
});

test('ensureTripUserInCity copy user sang DB đích trước khi tạo trip khác vùng', async () => {
  const { stores, inserts, deps } = createDeps({
    HCM: [createUser('HCM')],
    HN: [],
  });

  const result = await ensureTripUserInCity({
    userId: USER_ID,
    sourceCity: 'HCM',
    targetCity: 'HN',
  }, deps);

  assert.equal(result.created, true);
  assert.equal(inserts.length, 1);
  assert.equal(inserts[0].city, 'HN');
  assert.equal(stores.HN[0].id, USER_ID);
  assert.equal(stores.HN[0].thanh_pho, 'HN');
});

test('ensureTripUserInCity dÃ¹ng writable primary cho DB Ä‘Ã­ch', async () => {
  const { inserts, calls, deps } = createDeps({
    HCM: [createUser('HCM')],
    HN: [],
  });

  await ensureTripUserInCity({
    userId: USER_ID,
    sourceCity: 'HCM',
    targetCity: 'HN',
  }, deps);

  assert.equal(inserts.length, 1);
  assert.deepEqual(calls[0], { type: 'writable', city: 'HN' });
});

test('ensureTripUserInCity trả lỗi read-only nếu DB đích không cho ghi', async () => {
  const { deps } = createDeps({
    HCM: [createUser('HCM')],
    HN: [],
  }, { readOnlyCity: 'HN' });

  await assert.rejects(
    () => ensureTripUserInCity({
      userId: USER_ID,
      sourceCity: 'HCM',
      targetCity: 'HN',
    }, deps),
    { code: 'READ_ONLY_MODE' },
  );
});
