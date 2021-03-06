import getSecondLang from '@utils/getSecondLang';
import req from './request';

interface User {
  id: number;
  avatar: string;
  nickname: string;
  lang: string;
}

interface Message {
  text: string;
  source: string;
  user: User;
}

export default async (message: Message, me: User, users: User[]): Promise<string> => {
  const { id: authorId, lang: authorLang } = message.user;
  const { text, source } = message;
  const { id: myId, lang: myLang } = me;

  if (authorLang !== myLang) {
    if (source === myLang) {
      const translatedText = await req(text, source, authorLang);
      const texts = {
        originText: text,
        translatedText,
      };
      return JSON.stringify(texts);
    }
    const translatedText = await req(text, source, myLang);
    const texts = {
      originText: text,
      translatedText,
    };
    return JSON.stringify(texts);
  } else {
    if (authorId === myId) {
      if (message.source === myLang) {
        const secondLang = getSecondLang(users, myLang);
        const translatedText = await req(text, source, secondLang);
        const texts = {
          originText: text,
          translatedText,
        };
        return JSON.stringify(texts);
      }
      const translatedText = await req(text, source, myLang);
      const texts = {
        originText: text,
        translatedText,
      };
      return JSON.stringify(texts);
    } else {
      if (message.source === myLang) {
        const secondLang = getSecondLang(users, myLang);
        const translatedText = await req(text, source, secondLang);
        const texts = {
          originText: text,
          translatedText,
        };
        return JSON.stringify(texts);
      }
      const translatedText = await req(text, source, myLang);
      const texts = {
        originText: text,
        translatedText,
      };
      return JSON.stringify(texts);
    }
  }
};
