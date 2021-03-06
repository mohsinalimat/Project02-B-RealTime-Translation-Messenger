interface TextList {
  inputNickName: string;
  selectLanguage: string;
  enterRoom: string;
  createRoom: string;
  enterCode: string;
  submitCode: string;
  userList: string;
}

const textList = {
  ko: {
    inputNickName: '닉네임 입력',
    selectLanguage: '언어 선택',
    enterRoom: '대화 참여하기',
    createRoom: '방 만들기',
    enterCode: '참여 코드 6자리를 입력해주세요.',
    submitCode: '입장',
    userList: '대화 상대',
  },
  en: {
    inputNickName: 'Enter Nickname',
    selectLanguage: 'Select Language',
    enterRoom: 'Enter ChatRoom',
    createRoom: 'Create ChatRoom',
    enterCode: 'Please enter 6 digits of the participating code.',
    submitCode: 'Enter',
    userList: 'User List',
  },
};

const getText = (lang: 'ko' | 'en'): TextList => {
  return textList[lang];
};

export { getText };
export type { TextList };
